# = Domain
#
# A #Domain is a unique domain name entry, and contains various #Record entries to
# represent its data.
#
# The domain is used for the following purposes:
# * It is the $ORIGIN off all its records
# * It specifies a default $TTL

class Domain < ActiveRecord::Base
    # define helper constants and methods to handle domain types
    AUTHORITY_TYPES  = define_enum([:MASTER, :SLAVE],   :authority_type)
    ADDRESSING_TYPES = define_enum([:REVERSE, :NORMAL], :addressing_type)

    REVERSE_DOMAIN_SUFFIX = '.in-addr.arpa'

    # virtual attributes that ease new zone creation. If present, they'll be
    # used to create an SOA for the domain
    # SOA_FIELDS = [ :primary_ns, :contact, :refresh, :retry, :expire, :minimum, :ttl ]
    SOA::SOA_FIELDS.each do |field|
        delegate field.to_sym, (field.to_s + '=').to_sym, :to => :soa_record
    end

    acts_as_audited :protect => false
    has_associated_audits

    # associations
    belongs_to :view
    has_many   :records, :dependent => :destroy, :inverse_of => :domain
    has_one    :soa_record,    :class_name => 'SOA'
    has_many   :ns_records,    :class_name => 'NS'
    has_many   :mx_records,    :class_name => 'MX'
    has_many   :a_records,     :class_name => 'A'
    has_many   :txt_records,   :class_name => 'TXT'
    has_many   :cname_records, :class_name => 'CNAME'
    has_one    :loc_record,    :class_name => 'LOC'
    has_many   :aaaa_records,  :class_name => 'AAAA'
    has_many   :spf_records,   :class_name => 'SPF'
    has_many   :srv_records,   :class_name => 'SRV'
    has_many   :ptr_records,   :class_name => 'PTR'

    # validations
    validates_presence_of   :name
    validates_uniqueness_of :name
    validates_inclusion_of  :authority_type,  :in => AUTHORITY_TYPES.keys,  :message => "must be one of #{AUTHORITY_TYPES.keys.join(', ')}"
    validates_inclusion_of  :addressing_type, :in => ADDRESSING_TYPES.keys, :message => "must be one of #{ADDRESSING_TYPES.keys.join(', ')}"
    validates_presence_of   :ttl,        :if => :master?
    validates_associated    :soa_record, :if => :master? 
    validates_presence_of   :master,     :if => :slave?
    validates_format_of     :master,     :if => :slave?, :allow_blank => true, :with => /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/

    # callbacks
    # before_validation :set_addressing_type
    after_save        :save_soa_record

    # scopes
    default_scope         order("#{self.table_name}.name")
    scope :master,        where("#{self.table_name}.authority_type   = ?", MASTER).where("#{self.table_name}.addressing_type = ?", NORMAL)
    scope :slave,         where("#{self.table_name}.authority_type   = ?", SLAVE)
    scope :reverse,       where("#{self.table_name}.authority_type   = ?", MASTER).where("#{self.table_name}.addressing_type = ?", REVERSE)
    scope :nonreverse,    where("#{self.table_name}.addressing_type = ?",  NORMAL)
    scope :matching,      lambda { |query| where("#{self.table_name}.name LIKE ?", "%#{query}%") }
    scope :updated_since, lambda { |timestamp| Domain.where("#{self.table_name}.updated_at > ? OR #{self.table_name}.id IN (?)", timestamp, Record.updated_since(timestamp).select(:domain_id).pluck(:domain_id).uniq) }
    scope :noview,        where("#{self.table_name}.view_id IS NULL")
    scope :_reverse,      reverse # 'reverse' is an Array method; having an alias is useful when using the scope on associations

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
        rv = write_attribute('name', value)
        set_addressing_type
        rv
    end

    def addressing_type
        read_attribute('addressing_type').presence || set_addressing_type
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
        return if self.slave?
        soa_record.save or raise "[ERROR] unable to save SOA record (#{soa_record.errors.full_messages})"
    end

    # ------------- 'BIND9 export' utility methods --------------
    def zonefile_path

        dir = if self.slave?
                  self.view ? self.view.slaves_dir  : GloboDns::Config::SLAVES_DIR
              elsif self.reverse?
                  self.view ? self.view.reverse_dir : GloboDns::Config::REVERSE_DIR
              else
                  self.view ? self.view.zones_dir   : GloboDns::Config::ZONES_DIR
              end

        File.join(dir, 'db.' + self.name)
    end

    def zonefile_absolute_path
        File.join(GloboDns::Config::BIND_CONFIG_DIR, zonefile_path)
    end

    def to_bind9_conf(indent = '')
        str  = "#{indent}zone \"#{self.name}\" {\n"
        str << "#{indent}    type    #{self.slave? ? 'slave' : 'master'};\n"
        str << "#{indent}    file    \"#{zonefile_absolute_path}\";\n"
        str << "#{indent}    masters { #{self.master}; };\n" if self.slave?
        str << "#{indent}};\n\n"
        str
    end

    def to_zonefile(output)
        logger.warn "[WARN] called 'to_zonefile' on slave domain (#{self.id})" and return if slave?

        output = File.open(output, 'w') if output.is_a?(String) || output.is_a?(Pathname)

        output.puts "$ORIGIN #{self.name.chomp('.')}."
        output.puts "$TTL    #{self.ttl}"
        output.puts

        format = records_format
        records.order("FIELD(type, #{GloboDns::Config::RECORD_ORDER.map{|x| "'#{x}'"}.join(', ')}), name ASC").each do |record|
            record.domain = self
            record.update_serial(true) if record.is_a?(SOA)
            record.to_zonefile(output, format)
        end
    ensure
        output.close
    end

    private

    def set_addressing_type
        name.ends_with?(REVERSE_DOMAIN_SUFFIX) ? self.reverse! : self.normal!
    end

    def records_format
        sizes = self.records.select('MAX(LENGTH(name)) AS name, LENGTH(MAX(ttl)) AS ttl, MAX(LENGTH(type)) AS mtype, LENGTH(MAX(prio)) AS prio').first
        "%-#{sizes.name}s %-#{sizes.ttl}s IN %-#{sizes.mtype}s %-#{sizes.prio}s %s\n"
    end
end
