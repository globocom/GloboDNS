require 'scoped_finders'

# = Domain
#
# A #Domain is a unique domain name entry, and contains various #Record entries to
# represent its data.
#
# The zone is used for the following purposes:
# * It is the $ORIGIN off all its records
# * It specifies a default $TTL
#
class Domain < ActiveRecord::Base

  acts_as_audited :protect => false
  has_associated_audits

  belongs_to :user

  has_many :records, :dependent => :destroy

  has_one  :soa_record,    :class_name => 'SOA'
  has_many :ns_records,    :class_name => 'NS'
  has_many :mx_records,    :class_name => 'MX'
  has_many :a_records,     :class_name => 'A'
  has_many :txt_records,   :class_name => 'TXT'
  has_many :cname_records, :class_name => 'CNAME'
  has_one  :loc_record,    :class_name => 'LOC'
  has_many :aaaa_records,  :class_name => 'AAAA'
  has_many :spf_records,   :class_name => 'SPF'
  has_many :srv_records,   :class_name => 'SRV'
  has_many :ptr_records,   :class_name => 'PTR'

  validates_presence_of   :name
  validates_uniqueness_of :name
  validates_inclusion_of  :type, :in => %w(NATIVE MASTER SLAVE), :message => "must be one of NATIVE, MASTER, or SLAVE"
  validates_presence_of   :master, :if => :slave?
  validates_format_of     :master, :if => :slave?, :allow_blank => true, :with => /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
  validate                :validate_soa_record, :on => :create

  # Disable single table inheritence (STI)
  set_inheritance_column 'not_used_here'

  after_create  :create_soa_record
  before_update :set_soa_attributes
  after_update  :update_soa_record

  # Virtual attributes that ease new zone creation. If present, they'll be
  # used to create an SOA for the domain
  SOA_FIELDS = [ :name, :primary_ns, :contact, :refresh, :retry, :expire, :minimum, :ttl ]
  SOA_FIELDS.each do |f|
    unless self.column_names.include?(f.to_s)
      attr_accessor f
      validates_presence_of f, :on => :create, :unless => :slave?
    end
  end

  # Serial is optional, but will be passed to the SOA too
  attr_accessor :serial

  # Helper attributes for API clients and forms (keep it RESTful)
  attr_accessor :zone_template_id, :zone_template_name

  # Needed for acts_as_audited (TODO: figure out why this is needed...)
  #attr_accessible :type

  # Scopes
  scope :user,     lambda { |user| user.admin? ? nil : where(:user_id => user.id) }
  scope :reverse,  where('type != ?', 'SLAVE').where('name LIKE ?',     '%in-addr.arpa')
  scope :standard, where('type != ?', 'SLAVE').where('name NOT LIKE ?', '%in-addr.arpa')
  scope :slave,    where('type  = ?', 'SLAVE')
  default_scope    order('name')

  def self.search( string, page, user = nil )
    query = self.scoped
    query = query.user( user ) unless user.nil?
    query.where('name LIKE ?', "%#{string}%").paginate( :page => page )
  end

  # Are we a slave domain
  def slave?
    self.type == 'SLAVE'
  end

  def reverse?
    self.name.end_with?('.in-addr.arpa')
  end

  # return the records, excluding the SOA record
  def records_without_soa(query = nil)
    # records.all( :include => :domain ).select { |r| !r.is_a?( SOA ) }
    if query.nil? || query.blank? then
      # records.find(:all, :include => :domain ).select { |r| !r.is_a?( SOA ) }
      records.includes(:domain).where('type != ?', 'SOA')
    elsif query == '@' then
      records.includes(:domain).where('type != ?', 'SOA').where('name' => self.name)
      # records.find(:all, :conditions => ["records.name = ?", self.name], :include => :domain ).select { |r| !r.is_a?( SOA ) }
    else
      records.includes(:domain).where('type != ?', 'SOA').where('name LIKE ?', "%#{query}%")
      # records.find(:all, :conditions => ["records.name LIKE ?", "%#{query}%"], :include => :domain ).select { |r| !r.is_a?( SOA ) }
    end
  end

  # Expand our validations to include SOA details
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

  # Setup an SOA if we have the requirements
  def create_soa_record #:nodoc:
    return if self.slave?
    soa_record.save or raise "[ERROR] unable to save SOA record (#{soa_record.errors.full_messages})"
  end

  def set_soa_attributes
    soa_record.name = Record::fqdn(self.name, self.name) if self.name_changed?
    soa_record.ttl  = self.ttl  if self.ttl_changed?
  end

  def update_soa_record
    soa_record.save(false) if soa_record.changed?
  end

  def attach_errors(e)
    e.message.split(":")[1].split(",").uniq.each do |m|
      self.errors.add(m , '')
    end
  end

  # create & validate soa record
  def validate_soa_record
    return if self.slave?

    self.soa_record = SOA.new(:domain => self)
    SOA_FIELDS.each do |f|
      self.soa_record.send("#{f}=", send(f))
    end

    # override name with '@'
    self.soa_record.name = '@'

    self.soa_record.serial = serial unless serial.nil? # Optional
    if self.soa_record.valid?
      true
    else
      self.soa_record.errors.each do |field, message|
        errors.add(field, message)
      end
      false
    end
  end

  def zonefile_path
    dir = if self.slave?
            GloboDns::Config::SLAVES_DIR
          elsif self.reverse?
            GloboDns::Config::REVERSE_DIR
          else
            GloboDns::Config::ZONES_DIR
          end

    File.join(dir, 'db.' + self.name)
  end

  def zonefile_absolute_path
    File.join(GloboDns::Config::BIND_CONFIG_DIR, zonefile_path)
  end

  def to_bind9_conf
    <<-EOS
zone "#{self.name}" {
    type #{self.slave? ? 'slave' : 'master'};
    file "#{zonefile_absolute_path}";
};
    EOS
  end
end
