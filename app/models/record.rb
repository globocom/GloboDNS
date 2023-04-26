# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# = Record
#
# The parent class for all our DNS RR's. Used to apply global rules and logic
# that can easily be applied to any DNS RR's

class Record < ActiveRecord::Base
  include RecordsHelper
  include SyslogHelper
  include BindTimeFormatHelper
  include ModelSerializationWithWarnings

  belongs_to :domain, :inverse_of => :records

  attr_accessor :importing
  attr_accessible :domain_id, :name, :type, :content, :ttl, :prio, :weight, :port, :tag

  audited :associated_with => :domain
  self.non_audited_columns.delete(self.inheritance_column) # audit the 'type' column

  validates_presence_of      :domain
  validates_presence_of      :name
  validates_presence_of      :content
  validates_bind_time_format :ttl
  validate                   :validate_content_characters
  validate                   :validate_generate
  validate                   :validate_name_cname,                        :unless => :importing?
  validate                   :validate_name_format,                       :unless => :importing?
  validate                   :validate_recursive_subdomains,              :unless => :importing?
  validate                   :validate_same_record,                       :unless => :importing?
  validate                   :validate_txt,                               :unless => :importing?
  validate                   :ensure_quoted_content

  # validations that generate 'warnings' (i.e., doesn't prevent 'saving' the record)
  validation_scope :warnings do |scope|
    scope.validate :validate_same_name_and_type
    scope.validate :check_cname_content
    scope.validate :check_a_content
  end

  class_attribute :batch_soa_updates

  # this is needed here for generic form support, actual functionality
  # implemented in #SOA
  # attr_accessor   :primary_ns, :contact, :refresh, :retry, :expire, :minimum

  attr_protected :domain_id
  protected_attributes.delete('type') # 'type' is a special inheritance column use by Rails and not accessible by default;

  # before_validation :inherit_attributes_from_domain
  # before_save     :update_change_date
  # after_save      :update_soa_serial
  after_destroy :update_domain_timestamp
  after_save    :update_domain_timestamp
  after_update  :update_domain_timestamp

  before_save   :reset_prio
  before_save   :ipv6_remove_leading_zeros, :if => :is_ipv6?

  scope :sorted,        -> {order('name ASC')}
  scope :to_update_ttl, -> {without_soa.where('updated_at < ?',DateTime.now - 7.days).where('ttl >= ?', 60)}
  scope :without_soa,   -> {where('type != ?', 'SOA')}
  scope :soa,           -> {find_by(type: 'SOA')}
  scope :updated_since, -> (timestamp) { where('updated_at > ?', timestamp) }
  scope :matching,      -> (query){
    query.gsub!(/:0{,4}/,":").gsub!(/:{3,}/,"::") if query.include? ":"
    if query.index('*')
      query.gsub!(/\*/, '%')
      where('name LIKE ? OR content LIKE ?', query, query)
    else
      where('name = ? OR content = ?', query, query)
    end
  }

  # known record types
  @@record_types        = %w(AAAA A CERT CNAME DLV DNSKEY DS IPSECKEY KEY KX LOC MX NSEC3PARAM NSEC3 NSEC NS PTR RRSIG SIG SOA SPF SRV TA TKEY TSIG TXT CAA)
  @@high_priority_types = %w(A MX CNAME TXT NS)
  @@testable_types      = %w(A AAAA MX CNAME TXT SRV)
  @@caa_tags            = %w(issue issuewild ideof)

  cattr_reader :record_types
  cattr_reader :high_priority_types
  cattr_reader :testable_types
  cattr_reader :caa_tags

  def self.last_update
    select('updated_at').order('updated_at DESC').limit(1).first.updated_at
  end

  class << self

    # Restrict the SOA serial number updates to just one during the execution
    # of the block. Useful for batch updates to a zone
    def batch
      raise ArgumentError, "Block expected" unless block_given?

      self.batch_soa_updates = []
      yield
      self.batch_soa_updates = nil
    end

    # Make some ammendments to the acts_as_audited assumptions
    def configure_audits
      record_types.map(&:constantize).each do |klass|
        defaults = [klass.non_audited_columns ].flatten
        defaults.delete( klass.inheritance_column )
        # defaults.push( :change_date )
        klass.write_inheritable_attribute :non_audited_columns, defaults.flatten.map(&:to_s)
      end
    end

  end

  def shortname
    self[:name].gsub( /\.?#{self.domain.name}$/, '' )
  end

  def shortname=( value )
    self[:name] = value
  end

  def export_name
    (name == self.domain.name) ? '@' : (shortname.presence || (name + '.'))
  end

  # pull in the name & TTL from the domain if missing
  def inherit_attributes_from_domain #:nodoc:
    self.ttl ||= self.domain.ttl if self.domain
  end

  # update the change date for automatic serial number generation
  # def update_change_date
  #     self.change_date = Time.now.to_i
  # end

  # def update_soa_serial #:nodoc:
  #     unless self.type == 'SOA' || @serial_updated || self.domain.slave?
  #         self.domain.soa_record.update_serial!
  #         @serial_updated = true
  #     end
  # end

  # by default records don't support priorities, weight and port. Those who do can overwrite
  # this in their own classes.
  def supports_tag?
    false
  end

  def supports_prio?
    false
  end

  def supports_weight?
    false
  end

  def supports_port?
    false
  end

  def is_ipv6?
    self.type == 'AAAA'
  end

  def set_ownership(sub_component, user)
    if GloboDns::Config::DOMAINS_OWNERSHIP
      DomainOwnership::API.instance.post_domain_ownership_info(self.url, sub_component, "record", user) if DomainOwnership::API.instance.get_domain_ownership_info(self.url)[:sub_component].nil?
    end
  end

  def check_ownership(user, creation = false)
    if GloboDns::Config::DOMAINS_OWNERSHIP
      permission = DomainOwnership::API.instance.has_permission?(self.url, user)
      if (creation and !permission)
        sub_domain = self.domain.name
        splited = self.url.chomp(sub_domain).split(".")
        splited.delete_at(0) unless splited.empty?
        ended = false
        while(!permission and !ended)
          permission = DomainOwnership::API.instance.has_permission?(sub_domain, user)
          if splited.empty?
            ended = true
          else
            sub_domain = splited.pop + "." + sub_domain
          end
        end
      end
    end
    self.errors.add(:base, "User doesn't have ownership of '#{self.url}'") unless permission
    permission
  end

  def url
    if self.name.ends_with? '.'
      self.name.chomp('.')
    elsif self.name != '@'
      "#{self.name}.#{self.domain.name}"
    else
      self.domain.name
    end
  end

  def match_content content
    if self.type == "AAAA"
      self.content.split(":").collect{|i| i.to_i} == content.split(":").collect{|i| i.to_i}
    else
      self.content.delete("\"") == content or self.content == content or self.content == content+'.' or self.content+"."+self.domain.name == content or self.content+"."+self.domain.name+"." == content or self.content.chomp(self.domain.name+".") == content
    end
  end

  def domain_ttl
    if self.domain.ttl.ends_with? "D"
      return self.domain.ttl.to_i * 3600 * 24
    elsif self.domain.ttl.ends_with? "H"
      return self.domain.ttl.to_i * 3600
    elsif self.domain.ttl.ends_with? "M"
      return self.domain.ttl.to_i * 60
    else
      return self.domain.ttl.to_i
    end
  end

  def increase_ttl
    if GloboDns::Config::INCREASE_TTL
      new_ttl = self.ttl.to_i * 3

      if self.ttl.nil?
          Rails.logger.info "[Record] TTL of '#{self.name}' has the zone's default TTL (#{self.domain.name})"
      elsif new_ttl >= domain_ttl
        if self.update(ttl: nil)
          Rails.logger.info "[Record] '#{self.name}' (#{self.domain.name}) now have zone's default TTL"
        else
          Rails.logger.info "[Record] 'ERROR: Could not set TTL #{new_ttl} to #{self.name}' (#{self.domain.name})"
        end
      else
        if self.update(ttl: new_ttl)
          Rails.logger.info "[Record] '#{self.name}' (#{self.domain.name}) now have TTL of #{self.ttl}"
        else
          Rails.logger.info "[Record] 'ERROR: Could not set TTL #{new_ttl} to #{self.name}' (#{self.domain.name})"
        end
      end
    else
      Rails.logger.info "[Record] Increasing TTL is disabled"
    end
  end

  def ipv6_remove_leading_zeros
    self.content = ipv6_without_leading_zeros(self.content)
  end

  def ipv6_without_leading_zeros ip
    IPAddr.new(ip).to_s
  end

  def responding_from_dns_server server
    res = []
    resolver = Resolv::DNS.new(:nameserver => server)
    begin Timeout::timeout(1) {
        answers = resolver.getresources(self.url, self.resolve_resource_class)

        answers.each do |answer|
          case self.type
          when "A", "AAAA"
            res.push({name: self.name, ttl: answer.ttl, content: answer.address.to_s})
          when "TXT"
            res.push({name: self.name, ttl: answer.ttl, content: answer.strings.join.remove(" ")})
          when "PTR"
            # ?
          when "CNAME", "NS"
            res.push({name: self.name, ttl: answer.ttl, content: answer.name.to_s})
          when "SRV"
            res.push({name: self.name, ttl: answer.ttl, prio: answer.priority ,content: answer.target.to_s, port: answer.port, weight: answer.weight})
          when "MX"
            res.push({name: self.name, ttl: answer.ttl, content: answer.exchange.to_s, prio: answer.preference})
          end
        end
      }
    rescue
      res
    end
    res
  end

  def get_nameservers
    resolver = Resolv::DNS.new(:nameserver => GloboDns::Config::Bind::Master::IPADDR, :timeout => 5)
    servers = resolver.getresources(self.domain.name, Resolv::DNS::Resource::IN::NS)
    servers.collect {|server| server.name.to_s}
  end

  def resolve
    success = []
    failed = []

    # check authority servers response (servers from 'dig globo.com')
    servers = get_nameservers

    servers.each do |server|
      res = responding_from_dns_server(server)
      if !res.empty?
        res.each do |r|
          success.push({:content => r[:content], :prio => r[:prio], :port => r[:port], :weight => r[:weight], :server => "#{server}"})
        end
      else
        failed.push({:server => server})
      end
    end

    begin
      servers_extra = GloboDns::Config::ADDITIONAL_DNS_SERVERS
    rescue
      servers_extra = []
    end

    # check additional servers response (additional servers should at 'globodns.yml')
    servers_extra.each do |server|
      res = responding_from_dns_server(server)
      if !res.empty?
        res.each do |r|
          success.push({:content => r[:content], :prio => r[:prio], :port => r[:port], :weight => r[:weight], :server => "#{server}"})
        end
      else
        failed.push({:server => server})
      end
    end
    return {:success => success, :failed => failed}

    # p = Net::Ping::External.new self.content
    # self.warnings.add(:content, I18n.t('a_content_invalid', content: self.content, :scope => 'activerecord.errors.messages')) unless p.ping?

    # [GloboDns::Resolver::MASTER.resolve(self), GloboDns::Resolver::SLAVE.resolve(self)]
  end

  # return the Resolv::DNS resource instance, based on the 'type' column
  def self.resolv_resource_class(type)
    case type
    when 'A';     Resolv::DNS::Resource::IN::A
    when 'AAAA';  Resolv::DNS::Resource::IN::AAAA
    when 'CNAME'; Resolv::DNS::Resource::IN::CNAME
    when 'LOC';   Resolv::DNS::Resource::IN::TXT   # define a LOC class?
    when 'MX';    Resolv::DNS::Resource::IN::MX
    when 'NS';    Resolv::DNS::Resource::IN::NS
    when 'PTR';   Resolv::DNS::Resource::IN::PTR
    when 'SOA';   Resolv::DNS::Resource::IN::SOA
    when 'SPF';   Resolv::DNS::Resource::IN::TXT   # define a SPF class?
    when 'SRV';   Resolv::DNS::Resource::IN::SRV
    when 'TXT';   Resolv::DNS::Resource::IN::TXT
    end
  end

  def resolve_resource_class
    self.class.resolv_resource_class(self.type)
  end

  def after_audit
    syslog_audit(self.audits.last)
  end

  # fixed partial path, as we don't need a different partial for each record type
  def to_partial_path
    Record._to_partial_path
  end

  def self.fqdn(record_name, domain_name)
    domain_name += '.' unless domain_name[-1] == '.'
    if record_name == '@' || record_name.nil? || record_name.blank?
      domain_name
    elsif record_name[-1] == '.'
      record_name
      # elsif record_name.end_with?(domain_name)
      # record_name
    else
      record_name + '.' + domain_name
    end
  end

  def fqdn
    self.class.fqdn(self.name, self.domain.name)
  end

  def fqdn_content?
    !self.content.nil? && self.content[-1] == '.'
  end

  def ensure_quoted_content
    if ['CAA', 'TXT'].include? self.type
      quoted_content = self.content
      quoted_content.insert(0,"\"") unless content.starts_with? "\""
      quoted_content.insert(-1,"\"") unless content.ends_with? "\""

      self.content = quoted_content
    end
  end

  def to_zonefile(output, format)
    # FIXME: fix ending '.' of content on the importer
    content  = self.content
    content += '.' if self.content =~ /\.(?:com|net|org|br|in-addr\.arpa)$/ and self.type != "CAA"
    # content += '.' unless self.content[-1] == '.'                                 ||
    #                       self.type        == 'A'                                 ||
    #                       self.type        == 'AAAA'                              ||
    #                       self.content     =~ /\s\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}$/ || # ipv4
    #                       self.content     =~ /\s[a-fA-F0-9:]+$/                     # ipv6

    # FIXME: zone2sql sets prio = 0 for all records
    # host ttl IN CAA prio tag content
    tag = (self.type == 'CAA')? self.tag : ''
    prio = ((self.type == 'CAA' or self.type == 'MX' or self.type == 'SRV') || (self.prio && (self.prio > 0)) ? self.prio : '')
    weight = (self.type == 'SRV' || self.weight)? self.weight : ''
    port = (self.type == 'SRV' || self.port)? self.port : ''
    ttl = (self.generate?)? '' : self.ttl.to_s || ''
    name = (self.generate?)? "\$GENERATE #{self.range} #{self.name}" : self.name
    type = (self.generate?)? self.type : "IN #{self.type}"

    output.printf(format, name, ttl, type, prio || '', tag || '', weight || '', port || '', content)
  end

  def importing?
    !!importing
  end

  def validate_generate
    if self.generate?
      self.errors.add(:base, I18n.t('record_generate_bad_range', :scope => 'activerecord.errors.messages')) unless valid_range?
      self.errors.add(:base, I18n.t('record_generate_missing_dollar', :scope => 'activerecord.errors.messages')) unless self.name.include? '$' or self.content.include? '$'
    end
  end

  def valid_range?
    format = self.range.match(/^(\d+)\-(\d+)[\/\d]*$/)
    return format[2] > format[1] unless format.nil?

    false
  end

  def validate_name_cname
    return if self.generate?
    id = self.id || 0
    if self.type == 'CNAME' # check if the new cname record matches a old record name
      if record = Record.where(name: self.name, domain_id: self.domain_id).where("id != ?", id).first
        self.errors.add(:name, I18n.t('cname_name', :name => self.name, :type => record.type, :scope => 'activerecord.errors.messages'))
        return
      elsif record = Record.where(name: self.name+"."+self.domain.name+".", domain_id: self.domain_id).where("id != ?", id).first
        # check if there is a FQDN matching the record name
        self.errors.add(:name, I18n.t('cname_name', :name => self.name, :type => record.type, :scope => 'activerecord.errors.messages'))
        return
      elsif self.name.ends_with?'.' and record = Record.where(name: self.name.chomp("."+self.domain.name+"."), domain_id: self.domain_id).where("id != ?", id).first
        # check if there is a record name matching the FQDN
        self.errors.add(:name, I18n.t('cname_name', :name => self.name, :type => record.type, :scope => 'activerecord.errors.messages'))
        return
      end
    else # check if there is a CNAME record with the new record name
      unless self.domain.nil?
        if record = Record.where('id != ?', id).where('type = ?', 'CNAME').where('name' => self.name, 'domain_id' => self.domain_id).first
          self.errors.add(:name, I18n.t('cname_name_taken', :name => self.name, :scope => 'activerecord.errors.messages'))
          return
        elsif record = Record.where('id != ?', id).where('type = ?', 'CNAME').where('name' => self.name+"."+self.domain.name+".", 'domain_id' => self.domain_id).first
          # check if there is a FQDN matching the record name
          self.errors.add(:name, I18n.t('cname_name_taken', :name => self.name, :scope => 'activerecord.errors.messages'))

        elsif self.name.ends_with?'.' and record = Record.where('id != ?', id).where('type = ?', 'CNAME').where('name' => self.name.chomp("."+self.domain.name+"."), 'domain_id' => self.domain_id).first
          # check if there is a record name matching the FQDN
          self.errors.add(:name, I18n.t('cname_name_taken', :name => self.name, :scope => 'activerecord.errors.messages'))
          return
        end
      end
    end
  end


  def validate_name_format
    return if self.generate?
    # default implementation: validation of 'hostnames'
    return if self.name.blank? || self.name == '@'

    self.name.split('.').each_with_index do |part, index|
      if self.type == "SRV" or self.type == "TXT"
        unless (index == 0 && part == '*') || part =~ /^(?!\-)[a-zA-Z0-9\-_.]{,63}(?<!\-)$/
          self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
          return
        end
      else
        unless (index == 0 && part == '*') || part =~ /^(?![0-9]+$)(?!\-)[a-zA-Z0-9\-.]{,63}(?<!\-)$/
          self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
          return
        end
      end
    end
  end

  def validate_same_record
    id = self.id || 0
    if self.type!="CNAME" && record = Record.where('id != ?', id).where('name' => self.name, 'type' => self.type, 'domain_id' => self.domain_id, 'content' => self.content).first
      self.errors.add(:base, I18n.t('record_same_name_and_type_and_content', :name => record.name, :type => record.type, :content => record.content, :scope => 'activerecord.errors.messages'))
      return
    end
  end


  def validate_same_name_and_type
    id = self.id || 0
    if self.type!="CNAME" && record = Record.where('id != ?', id).where('name' => self.name, 'type' => self.type, 'domain_id' => self.domain_id, 'content' => self.content).first
      return
    elsif self.type!="CNAME" && record = self.class.where('id != ?', id).where('content != ?', self.content).where('name' => self.name, 'type' => self.type, 'domain_id' => self.domain_id).first
      self.warnings.add(:base, I18n.t('record_same_name_and_type', :name => record.name, :type => record.type, :content => record.content, :scope => 'activerecord.errors.messages'))
    end
  end

  def validate_recursive_subdomains
    return if self.domain.nil? || self.domain.name.blank?   || self.name.blank? ||
      self.name == '@' || self.name.index('.').nil? || self.name[-1] == '.'

    domain_name = self.domain.name
    conditions  = nil


    self.name.split('.').reverse_each do |part|
      domain_name = "#{part}.#{domain_name}"
      condition   = Domain.arel_table[:name].eq(domain_name)
      conditions  = conditions ? conditions.or(condition) : condition
    end

    if domain = Domain.where(conditions).first
      self.errors.add(:name, I18n.t('recursive_subdomain', :domain => domain.name, :scope => 'activerecord.errors.messages'))
    end
  end

  def validate_txt
    if self.type == "TXT"
      strings = self.content.split("\"\"")
      strings.each do |s|
        self.errors.add(:content, I18n.t('string_txt_exceeds', :scope => 'activerecord.errors.messages')) if s.sub("\"","").size > 257
      end
    end
  end

  def check_cname_content
    if self.type == "CNAME" and self.content.ascii_only?
      if self.content.ends_with? "."
        dns = Resolv::DNS.new
        url = self.content[0...-1]
        begin
          dns.getaddress(url)
        rescue
          self.warnings.add(:content, I18n.t('cname_content_fqdn_invalid', content: self.content, :scope => 'activerecord.errors.messages'))
        end
      else
        records = self.domain.records.map{|r| r.name}
        self.warnings.add(:content, I18n.t('cname_content_record_invalid', content: self.content, :scope => 'activerecord.errors.messages')) unless records.include? self.content
      end
    end
    return
  end

  def check_a_content
    if self.type == "A"
      p = Net::Ping::External.new self.content
      self.warnings.add(:content, I18n.t('a_content_invalid', content: self.content, :scope => 'activerecord.errors.messages')) unless p.ping?
    end

    return
  end

  # checks if content has only ascii characters
  def validate_content_characters
    if !self.content.ascii_only?
      # ascii_only
      self.errors.add(:content, I18n.t('ascii_only', :scope => 'activerecord.errors.messages'))
    end
  end

  # Checks if this record is a replica of another
  def same_as? other_record
    self.name    == other_record.name &&
    self.ttl     == other_record.ttl  &&
    self.type    == other_record.type &&
    self.content == other_record.content
  end

  private

  def update_domain_timestamp
    self.transaction do
      Domain.where(name: self.domain.name).each(&:touch)
    end
  end

  def reset_prio
    self.prio = nil unless supports_prio?
  end

  # append the domain name to the +name+ field if missing
  # def append_domain_name!
  #     self[:name] = self.domain.name if self[:name].blank?
  #     unless self[:name].index( self.domain.name )
  #         puts "[append_domain_name] appending domain name (#{self[:name]} / #{self.domain.name})"
  #         self[:name] << ".#{self.domain.name}"
  #     end
  # end
end
