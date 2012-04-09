# See #Record

# = Record
#
# The parent class for all our DNS RR's. Used to apply global rules and logic
# that can easily be applied to any DNS RR's
#
class Record < ActiveRecord::Base

  acts_as_audited :associated_with => :domain
  self.non_audited_columns.delete( self.inheritance_column ) # Audit the 'type' column

  belongs_to :domain, :inverse_of => :records

  validates_presence_of     :domain
  validates_presence_of     :name
  validates_numericality_of :ttl, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => true

  class_attribute :batch_soa_updates

  # This is needed here for generic form support, actual functionality
  # implemented in #SOA
  attr_accessor   :primary_ns, :contact, :refresh, :retry, :expire, :minimum

  # 'type' is a special inheritance column use by Rails and not accessible by default;
  protected_attributes.delete('type')

  before_validation :inherit_attributes_from_domain
  before_save       :update_change_date
  after_save        :update_soa_serial

  scope :sorted,      order('name ASC')
  scope :without_soa, where('type != ?', 'SOA')
  scope :matching,    lambda { |query| where('name LIKE ? OR content LIKE ?', "%#{query}%", "%#{query}%") }

  # Known record types
  @@record_types = ['A', 'AAAA', 'CNAME', 'LOC', 'MX', 'NS', 'PTR', 'SOA', 'SPF', 'SRV', 'TXT']
  cattr_reader :record_types

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
        defaults.push( :change_date )
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

  # Nicer representation of the domain as XML
  def to_xml_with_cleanup(options = {}, &block)
    to_xml_without_cleanup(options, &block)
  end
  alias_method_chain :to_xml, :cleanup

  # Pull in the name & TTL from the domain if missing
  def inherit_attributes_from_domain #:nodoc:
    unless self.domain_id.nil?
      # append_domain_name!
      self.ttl ||= self.domain.ttl
    end
  end

  # Update the change date for automatic serial number generation
  def update_change_date
    self.change_date = Time.now.to_i
  end

  def update_soa_serial #:nodoc:
    unless self.type == 'SOA' || @serial_updated || self.domain.slave?
      self.domain.soa_record.update_serial!
      @serial_updated = true
    end
  end

  # By default records don't support priorities. Those who do can overwrite
  # this in their own classes.
  def supports_prio?
    false
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

  def to_zonefile(format)
    # FIXME: fix ending '.' of content on the importer
    content  = self.content
    content += '.' if self.content =~ /\.(?:com|net|org|br|in-addr\.arpa)$/
    # content += '.' unless self.content[-1] == '.'                                 ||
    #                       self.type        == 'A'                                 ||
    #                       self.type        == 'AAAA'                              ||
    #                       self.content     =~ /\s\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}$/ || # ipv4
    #                       self.content     =~ /\s[a-fA-F0-9:]+$/                     # ipv6

    # FIXME: zone2sql sets prio = 0 for all records
    prio = (self.type == 'MX' || (self.prio && (self.prio > 0)) ? self.prio : '')

    # output.printf(format, record.name, record.ttl, record.type, prio, content)
    sprintf(format, self.name, self.ttl, self.type, prio || '', content)
  end

  private

  # Append the domain name to the +name+ field if missing
  def append_domain_name!
    self[:name] = self.domain.name if self[:name].blank?
    unless self[:name].index( self.domain.name )
      puts "[append_domain_name] appending domain name (#{self[:name]} / #{self.domain.name})"
      self[:name] << ".#{self.domain.name}"
    end
  end
end
