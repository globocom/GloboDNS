# = Domain
#
# A #Domain is a unique domain name entry, and contains various #Record entries to
# represent its data.
#
# The domain is used for the following purposes:
# * It is the $ORIGIN off all its records
# * It specifies a default $TTL

class Domain < ActiveRecord::Base
    # virtual attributes that ease new zone creation. If present, they'll be
    # used to create an SOA for the domain
    # SOA_FIELDS = [ :primary_ns, :contact, :refresh, :retry, :expire, :minimum, :ttl ]
    SOA::SOA_FIELDS.each do |field|
        delegate field.to_sym, (field.to_s + '=').to_sym, :to => :soa_record
    end

    TYPES = [:MASTER, :SLAVE].inject(Hash.new) do |hash, type|
        type_str = type.to_s
        const_set(('TYPE_' + type_str).to_sym, type_str)
        hash[type_str] = type
        hash
    end

    acts_as_audited :protect => false
    has_associated_audits

    self.inheritance_column = '__invalid_value__' # disable single table inheritence (STI)

    has_many :records, :dependent => :destroy, :inverse_of => :domain

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
    validates_presence_of   :ttl
    validates_uniqueness_of :name
    validates_inclusion_of  :type, :in => TYPES.keys, :message => "must be one of #{TYPES.keys.join(', ')}"
    validates_presence_of   :master, :if => :slave?
    validates_format_of     :master, :if => :slave?, :allow_blank => true, :with => /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
    validates_associated    :soa_record, :unless => :slave? 
    # validate              :validate_soa_record, :on => :create

    after_save  :save_soa_record
    # before_update :set_soa_attributes
    # after_update  :update_soa_record

    # Serial is optional, but will be passed to the SOA too
    # attr_accessor :serial

    # Helper attributes for API clients and forms (keep it RESTful)
    # attr_accessor :domain_template_id, :domain_template_name

    # Needed for acts_as_audited (TODO: figure out why this is needed...)
    #attr_accessible :type

    # scopes
    scope :master,        where("#{self.table_name}.type != ?", TYPE_SLAVE).where("#{self.table_name}.name NOT LIKE ?", '%in-addr.arpa')
    scope :slave,         where("#{self.table_name}.type  = ?", TYPE_SLAVE)
    scope :nonslave,      where("#{self.table_name}.type != ?", TYPE_SLAVE)
    scope :reverse,       where("#{self.table_name}.type != ?", TYPE_SLAVE).where("#{self.table_name}.name LIKE ?", '%in-addr.arpa')
    scope :nonreverse,    where("#{self.table_name}.name NOT LIKE ?", '%in-addr.arpa')
    scope :matching,      lambda { |query| where("#{self.table_name}.name LIKE ?", "%#{query}%") }
    scope :updated_since, lambda { |timestamp| Domain.where("#{self.table_name}.updated_at > ? OR #{self.table_name}.id IN (?)", timestamp, Record.updated_since(timestamp).select(:domain_id).pluck(:domain_id).uniq) }
    default_scope         order("#{self.table_name}.name")

    def soa_record
        super || (self.soa_record = SOA.new.tap{|soa| soa.domain = self})
    end

    def slave?
        self.type == 'SLAVE'
    end

    def reverse?
        self.name.end_with?('.in-addr.arpa')
    end

    def updated_since?(timestamp)
        self.updated_at > timestamp
    end

    # return the records, excluding the SOA record
    def records_without_soa
        records.includes(:domain).where('type != ?', 'SOA')
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

    # def set_soa_attributes
    #     soa_record.ttl = self.ttl if self.ttl_changed?
    # end

    # def update_soa_record
    #     soa_record.save(:validate => false) if soa_record.changed?
    # end

    # def attach_errors(e)
    #     e.message.split(":")[1].split(",").uniq.each do |m|
    #         self.errors.add(m , '')
    #     end
    # end

    # validate soa record
    # def validate_soa_record
    #     return true if self.slave? || (self.soa_record && self.soa_record.valid?)

    #     self.soa_record = SOA.new(:domain => self)
    #     SOA_FIELDS.each do |f|
    #         self.soa_record.send("#{f}=", send(f))
    #     end

    #     # override name with '@'
    #     self.soa_record.name = '@'

    #     self.soa_record.serial = serial unless serial.nil? # Optional
    #     if self.soa_record.valid?
    #         true
    #     else
    #         self.soa_record.errors.each do |field, message|
    #             errors.add(field, message)
    #         end
    #         false
    #     end
    # end

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
        str  = "zone \"#{self.name}\" {\n"
        str << "    type    #{self.slave? ? 'slave' : 'master'};\n"
        str << "    file    \"#{zonefile_absolute_path}\";\n"
        str << "    masters { #{self.master}; };\n" if self.slave?
        str << "};\n\n"
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

    def records_format
        sizes = self.records.select('MAX(LENGTH(name)) AS name, LENGTH(MAX(ttl)) AS ttl, MAX(LENGTH(type)) AS mtype, LENGTH(MAX(prio)) AS prio').first
        "%-#{sizes.name}s %-#{sizes.ttl}s IN %-#{sizes.mtype}s %-#{sizes.prio}s %s\n"
    end
end
