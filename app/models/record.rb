# = Record
#
# The parent class for all our DNS RR's. Used to apply global rules and logic
# that can easily be applied to any DNS RR's

class Record < ActiveRecord::Base
    include SyslogHelper
    include BindTimeFormatHelper
    include ModelSerializationWithWarnings

    belongs_to :domain, :inverse_of => :records

    audited :associated_with => :domain
    self.non_audited_columns.delete(self.inheritance_column) # audit the 'type' column

    validates_presence_of      :domain
    validates_presence_of      :name
    validates_bind_time_format :ttl
    # validates_numericality_of :ttl, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => true

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
    before_save   :reset_prio

    scope :sorted,        order('name ASC')
    scope :without_soa,   where('type != ?', 'SOA')
    scope :updated_since, lambda { |timestamp| where('updated_at > ?', timestamp) }
    scope :matching,      lambda { |query|
        if query.index('*')
            query.gsub!(/\*/, '%')
            where('name LIKE ? OR content LIKE ?', query, query)
        else
            where('name = ? OR content = ?', query, query)
        end
    }

    # known record types
    @@record_types = %w(AAAA A CERT CNAME DLV DNSKEY DS IPSECKEY KEY KX LOC MX NSEC3PARAM NSEC3 NSEC NS PTR RRSIG SIG SOA SPF SRV TA TKEY TSIG TXT)

    cattr_reader :record_types

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

    # by default records don't support priorities. Those who do can overwrite
    # this in their own classes.
    def supports_prio?
        false
    end

    def resolve
        [GloboDns::Resolver::MASTER.resolve(self), GloboDns::Resolver::SLAVE.resolve(self)]
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

    def to_zonefile(output, format)
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

        output.printf(format, self.name, self.ttl.to_s || '', self.type, prio || '', content)
    end

    private

    def update_domain_timestamp
        self.domain.touch
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
