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

# = Domain
#
# A #Domain is a unique domain name entry, and contains various #Record entries to
# represent its data.
#
# The domain is used for the following purposes:
# * It is the $ORIGIN off all its records
# * It specifies a default $TTL

class Domain < ActiveRecord::Base
    include SyslogHelper
    include BindTimeFormatHelper

    # define helper constants and methods to handle domain types
    AUTHORITY_TYPES  = define_enum(:authority_type,  [:MASTER, :SLAVE, :FORWARD, :STUB, :HINT], ['M', 'S', 'F', 'U', 'H'])
    ADDRESSING_TYPES = define_enum(:addressing_type, [:REVERSE, :NORMAL], ['R', 'N'])

    REVERSE_DOMAIN_SUFFIXES = ['.in-addr.arpa', '.ip6.arpa']

    # virtual attributes that ease new zone creation. If present, they'll be
    # used to create an SOA for the domain
    # SOA_FIELDS = [ :primary_ns, :contact, :refresh, :retry, :expire, :minimum, :ttl ]
    SOA::SOA_FIELDS.each do |field|
        delegate field.to_sym, (field.to_s + '=').to_sym, :to => :soa_record
    end

    attr_accessor :importing
    attr_accessible :user_id, :name, :master, :last_check, :notified_serial, :account, :ttl, :notes, :authority_type, :addressing_type, :view_id, \
    :primary_ns, :contact, :refresh, :retry, :expire, :minimum

    audited :protect => false
    has_associated_audits

    # associations
    belongs_to :view
    # A sibling domain from where we borrow identical records.
    belongs_to :sibling, class_name: 'Domain'
    has_many   :records,            :dependent => :destroy,      :inverse_of => :domain
    has_one    :soa_record,         :class_name => 'SOA',        :inverse_of => :domain
    has_many   :aaaa_records,       :class_name => 'AAAA',       :inverse_of => :domain
    has_many   :a_records,          :class_name => 'A',          :inverse_of => :domain
    has_many   :cert_records,       :class_name => 'CERT',       :inverse_of => :domain
    has_many   :cname_records,      :class_name => 'CNAME',      :inverse_of => :domain
    has_many   :dlv_records,        :class_name => 'DLV',        :inverse_of => :domain
    has_many   :dnskey_records,     :class_name => 'DNSKEY',     :inverse_of => :domain
    has_many   :ds_records,         :class_name => 'DS',         :inverse_of => :domain
    has_many   :ipseckey_records,   :class_name => 'IPSECKEY',   :inverse_of => :domain
    has_many   :key_records,        :class_name => 'KEY',        :inverse_of => :domain
    has_many   :kx_records,         :class_name => 'KX',         :inverse_of => :domain
    has_many   :loc_records,        :class_name => 'LOC',        :inverse_of => :domain
    has_many   :mx_records,         :class_name => 'MX',         :inverse_of => :domain
    has_many   :nsec3param_records, :class_name => 'NSEC3PARAM', :inverse_of => :domain
    has_many   :nsec3_records,      :class_name => 'NSEC3',      :inverse_of => :domain
    has_many   :nsec_records,       :class_name => 'NSEC',       :inverse_of => :domain
    has_many   :ns_records,         :class_name => 'NS',         :inverse_of => :domain
    has_many   :ptr_records,        :class_name => 'PTR',        :inverse_of => :domain
    has_many   :rrsig_records,      :class_name => 'RRSIG',      :inverse_of => :domain
    has_many   :sig_records,        :class_name => 'SIG',        :inverse_of => :domain
    has_many   :spf_records,        :class_name => 'SPF',        :inverse_of => :domain
    has_many   :srv_records,        :class_name => 'SRV',        :inverse_of => :domain
    has_many   :ta_records,         :class_name => 'TA',         :inverse_of => :domain
    has_many   :tkey_records,       :class_name => 'TKEY',       :inverse_of => :domain
    has_many   :tsig_records,       :class_name => 'TSIG',       :inverse_of => :domain
    has_many   :txt_records,        :class_name => 'TXT',        :inverse_of => :domain

    # validations
    validates_presence_of      :name
    validates_uniqueness_of    :name, :scope => :view_id
    validates_inclusion_of     :authority_type,  :in => AUTHORITY_TYPES.keys,  :message => "must be one of #{AUTHORITY_TYPES.keys.join(', ')}"
    validates_inclusion_of     :addressing_type, :in => ADDRESSING_TYPES.keys, :message => "must be one of #{ADDRESSING_TYPES.keys.join(', ')}"
    validates_presence_of      :ttl,        :if => :master?
    validates_bind_time_format :ttl,        :if => :master?
    validates_associated       :soa_record, :if => :master?
    validates_presence_of      :master,     :if => :slave?
    validate                   :validate_recursive_subdomains, :unless => :importing?

    # validations that generate 'warnings' (i.e., doesn't prevent 'saving' the record)
    # validation_scope :warnings do |scope|
    # end

    # callbacks
    after_save :save_soa_record

    # scopes
    default_scope             { order("#{self.table_name}.name") }
    scope :master,            -> {where("#{self.table_name}.authority_type   = ?", MASTER).where("#{self.table_name}.addressing_type = ?", NORMAL)}
    scope :slave,             -> {where("#{self.table_name}.authority_type   = ?", SLAVE)}
    scope :forward,           -> {where("#{self.table_name}.authority_type   = ?", FORWARD)}
    scope :master_or_reverse, -> {where("#{self.table_name}.authority_type   = ?", MASTER)}
    scope :reverse,           -> {where("#{self.table_name}.authority_type   = ?", MASTER).where("#{self.table_name}.addressing_type = ?", REVERSE)}
    scope :nonreverse,        -> {where("#{self.table_name}.addressing_type  = ?", NORMAL)}
    scope :noview,            -> {where("#{self.table_name}.view_id IS NULL")}
    scope :_reverse,          -> {reverse} # 'reverse' is an Array method; having an alias is useful when using the scope on associations
    scope :updated_since,     -> (timestamp) {Domain.where("#{self.table_name}.updated_at > ? OR #{self.table_name}.id IN (?)", timestamp, Record.updated_since(timestamp).select(:domain_id).pluck(:domain_id).uniq) }
    scope :matching,          -> (query){
                                    if query.index('*')
                                        where("#{self.table_name}.name LIKE ?", query.gsub(/\*/, '%'))
                                    else
                                        where("#{self.table_name}.name" => query)
                                    end
                                }

    def self.last_update
        select('updated_at').reorder('updated_at DESC').limit(1).first.updated_at
    end

    # instantiate soa_record association on domain creation (this is required as
    # we delegate several attributes to the 'soa_record' association and want to
    # be able to set these attributes on 'Domain.new')
    def soa_record
        super || (self.soa_record = SOA.new.tap{|soa| soa.domain = self})
    end

    # deprecated in favor of the 'updated_since' scope
    def updated_since?(timestamp)
        self.updated_at > timestamp
    end

    # return the records, excluding the SOA record
    def records_without_soa
        records.includes(:domain).where('type != ?', 'SOA')
    end

    def name=(value)
        rv = write_attribute :name, value == '.' ? value : value.chomp('.')
        set_addressing_type
        rv
    end

    def addressing_type
        read_attribute('addressing_type').presence || set_addressing_type
    end

    # aliases to mascarade the fact that we're reusing the "master" attribute
    # to hold the "forwarder" values of domains with "forward" type
    def forwarder; self.master; end
    def forwarder=(val); self.master = val; end

    def importing?
        !!importing
    end

    # expand our validations to include SOA details
    def after_validation_on_create #:nodoc:
        soa = SOA.new( :domain => self )
        SOA_FIELDS.each do |f|
            soa.send( "#{f}=", send( f ) )
        end
        soa.serial = serial unless serial.nil? # Optional

        unless soa.valid?
            soa.errors.each_full do |e|
                errors.add_to_base e
            end
        end
    end

    # setup an SOA if we have the requirements
    def save_soa_record #:nodoc:
        return unless self.master?
        soa_record.save or raise "[ERROR] unable to save SOA record (#{soa_record.errors.full_messages})"
    end

    def after_audit
        syslog_audit(self.audits.last)
    end

    # ------------- 'BIND9 export' utility methods --------------
    def query_key_name
        (self.view || View.first).try(:key_name)
    end

    def query_key
        (self.view || View.first).try(:key)
    end

    def subdir_path
        #caches and returns
        @subdir_path ||= generate_subdir_path
    end

    def zonefile_dir
        dir = if self.slave?
                  self.view ? self.view.slaves_dir   : GloboDns::Config::SLAVES_DIR
              elsif self.forward?
                  self.view ? self.view.forwards_dir : GloboDns::Config::FORWARDS_DIR
              elsif self.reverse?
                  self.view ? self.view.reverse_dir  : GloboDns::Config::REVERSE_DIR
              else
                  self.view ? self.view.zones_dir    : GloboDns::Config::ZONES_DIR
              end
        File::join dir, subdir_path
    end

    def zonefile_path
        if self.slave?
            File.join(zonefile_dir, 'dbs.' + self.name)
        else
            File.join(zonefile_dir, 'db.' + self.name)
        end
    end

    def to_bind9_conf(zones_dir, indent = '')
        view = self.view || View.first
        str  = "#{indent}zone \"#{self.name}\" {\n"
        str << "#{indent}    type       #{self.authority_type_str.downcase};\n"
        str << "#{indent}    file       \"#{File.join(zones_dir, zonefile_path)}\";\n" unless self.forward?
        str << "#{indent}    masters    { #{self.master.strip.chomp(';')}; };\n"       if self.slave?   && self.master
        str << "#{indent}    forwarders { #{self.forwarder.strip.chomp(';')}; };\n"    if self.forward? && (self.master || self.slave?)
        str << "#{indent}};\n\n"
        str
    end

    def to_zonefile(output)
        logger.warn "[WARN] called 'to_zonefile' on slave/forward domain (#{self.id})" and return if slave? || forward?

        output = File.open(output, 'w') if output.is_a?(String) || output.is_a?(Pathname)

        output.puts "$ORIGIN #{self.name.chomp('.')}."
        output.puts "$TTL    #{self.ttl}"
        output.puts

        output_records(output, self.sibling.records, output_soa: true) if sibling
        output_records(output, self.records, output_soa: !sibling) #only show this soa if the soa for the sibling hasn't been shown yet.
    ensure
        output.close if output.is_a?(File)
    end

    def validate_recursive_subdomains
        return if self.name.blank?

        record_name = nil
        domain_name = self.name.clone
        while suffix = domain_name.slice!(/.*?\./).try(:chop)
            record_name = record_name ? "#{record_name}.#{suffix}" : suffix
            records     = Record.joins(:domain).
                                  where("#{Record.table_name}.name = ? OR #{Record.table_name}.name LIKE ?", record_name, "%.#{record_name}").
                                  where("#{Domain.table_name}.name = ?", domain_name).all
            if records.any?
                records_excerpt = self.class.truncate(records.collect {|r| "\"#{r.name} #{r.type} #{r.content}\" from \"#{r.domain.name}\"" }.join(', '))
                self.errors.add(:base, I18n.t('records_unreachable_by_domain', :records => records_excerpt, :scope => 'activerecord.errors.messages'))
                return
            end
        end
    end
    
    # Find a domain that has the same name, to search for replicated records.
    # The parameter 'save' tells if the method shall persist its changes in the end.
    def set_sibling save=false
        siblings = Domain::where(name: self.name)
        siblings.reject! do |sib| sib.id == self.id end if self.persisted?
        sibling = siblings.first
        if sibling
            Domain.transaction do
                self.sibling = sibling
                merge_records(sibling)
                if save
                    raise ActiveRecord::Rollback unless self.save
                end
            end
        end
    end

    private

    def set_addressing_type
        REVERSE_DOMAIN_SUFFIXES.each do |suffix|
            self.reverse! and return if name.ends_with?(suffix)
        end
        self.normal!
    end

    # Output to the given output stream
    # the records from the given colection.
    # Accepts, as options, output_soa: boolean
    def output_records output, records, options={output_soa: true}
        format = records_format records
        records.order("FIELD(type, #{GloboDns::Config::RECORD_ORDER.map{|x| "'#{x}'"}.join(', ')}), name ASC").each do |record|
            record.domain = self
            unless record.is_a?(SOA) && !options[:output_soa]
                record.update_serial(true) if record.is_a?(SOA)
                record.to_zonefile(output, format)
            end
        end
    end

    def records_format records
        sizes = records.select('MAX(LENGTH(name)) AS name, LENGTH(MAX(ttl)) AS ttl, MAX(LENGTH(type)) AS mtype, LENGTH(MAX(prio)) AS prio').first
        "%-#{sizes.name}s %-#{sizes.ttl}s IN %-#{sizes.mtype}s %-#{sizes.prio}s %s\n"
    end

    def self.truncate(str, limit = 80)
        str.size > limit ? str[0..limit] + '...' : str
    end

    def generate_subdir_path
        config_depth = GloboDns::Config::SUBDIR_DEPTH
        depth = config_depth.is_a?(Integer) ? config_depth : Integer(config_depth, 10) rescue 0
        # uses the first alphanumeric characters to create subdirs, up to GloboDns::Config::SUBDIR_DEPTH levels.
        File::join self.name.split('').select{|char| char.match /[a-zA-Z0-9]/}.first(depth)
    end

    # If a record for this domain is identical
    # a record for the other domain, instead of creating
    # a new copy of it, just uses the sibling pointing
    def merge_records(other_domain)
        other_records = other_domain.records
        # identical_other_records = [] # if you want to cache the records that are identical on other_domain
        # partition returns 2 arrays: first passes the predicate. Second doesn't
        identical_records, new_records = self.records.partition do |record|
            identical = false
            # is there any other record ...
            other_records.each do |other_record|
                # that is the same as ours?
                if other_record.same_as? record
                  # set the flag to true
                  identical = true
                  # and cache it to merge
                  # identical_other_records << other_record # if you want to cache the records that are identical on other_domain
                end
            end
            identical
        end
        self.records = new_records
    end
end
