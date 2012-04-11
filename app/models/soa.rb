# See #SOA

# = Start of Authority Record
# Defined in RFC 1035. The SOA defines global parameters for the zone (domain).
# There is only one SOA record allowed in a zone file.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/soa.html
#
class SOA < Record

    validates_presence_of     :primary_ns, :content, :serial, :refresh, :retry, :expire, :minimum
    validates_numericality_of :serial, :refresh, :retry, :expire, :allow_blank => true, :greater_than_or_equal_to => 0
    validates_numericality_of :minimum, :allow_blank => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10800
    validates_uniqueness_of   :domain_id, :on => :update
    validates                 :contact, :presence => true, :hostname => true
    validates                 :name,    :presence => true, :hostname => true

    before_validation :set_content
    before_validation :update_serial
    after_initialize  :update_convenience_accessors

    attr_accessible :name, :ttl, :prio, :content, :primary_ns, :contact, :refresh, :retry, :expire, :minimum

    # The portions of the +content+ column that make up our SOA fields
    SOA_FIELDS = %w{primary_ns contact serial refresh retry expire minimum}

    # This allows us to have these convenience attributes act like any other
    # column in terms of validations
    SOA_FIELDS.each do |soa_entry|
        attr_accessor soa_entry
        attr_reader   soa_entry + '_was'
        define_method "#{soa_entry}_before_type_cast" do
            instance_variable_get("@#{soa_entry}")
        end
    end

    # Treat contact specially, replacing the first period with an @ if
    # no @'s are present
    # def contact=( email )
    #   if !email.nil? && email.index('@').nil?
    #     email.sub!('.', '@')
    #   end

    #   @contact = email
    # end

    # Hook into #reload
    def reload_with_content
        reload_without_content
        update_convenience_accessors
    end
    alias_method_chain :reload, :content

    # Updates the serial number to the next logical one. Format of the generated
    # serial is YYYYMMDDNN, where NN is the number of the change for the day.
    # 01 for the first change, 02 the seconds, etc...
    #
    # If the serial number is 0, we opt for PowerDNS's automatic serial number
    # generation
    def update_serial
        self.serial = Time.now.strftime('%Y%m%d%H%M%S')
        # unless Record.batch_soa_updates.nil?
        #   if Record.batch_soa_updates.include?( self.id )
        #     return
        #   end

        #   Record.batch_soa_updates << self.id
        # end

        # return if self.content_changed?

        # date_serial = Time.now.strftime( "%Y%m%d00" ).to_i

        # self.serial = if self.serial.nil? || date_serial > self.serial
        #     date_serial
        # else
        #    self.serial + 1
        # end
    end

    # Same as #update_serial and saves the record
    def update_serial!
        if respond_to?( :without_auditing )
            without_auditing do
                update_serial
                save
            end
        else
            update_serial
            save
        end
    end

    # Nicer representation of the domain as XML
    def to_xml(options = {}, &block)
        to_xml_without_cleanup options.merge(:methods => SOA_FIELDS)
    end

    def set_content
        self.content = SOA_FIELDS.map { |f| instance_variable_get("@#{f}").to_s  }.join(' ')
    end

    def export_name
        '@'
    end

    def resolv_resource_class
        Resolv::DNS::Resource::IN::SOA
    end

    def to_partial_path
        "#{self.class.superclass.name.underscore.pluralize}/soa_record"
    end

    def match_resolv_resource(resource)
        resource.mname.to_s == self.primary_ns.chomp('.')  &&
            resource.rname.to_s == self.contact.chomp('.') &&
            resource.serial     == self.serial             &&
            resource.refresh    == self.refresh            &&
            resource.retry      == self.retry              &&
            resource.expire     == self.expire             &&
            resource.minimum    == self.minimum
    end

    private

    # Update our convenience accessors when the object has changed
    def update_convenience_accessors
        return if self.content.blank?

        soa_fields = self.content.split(/\s+/)
        raise Exception.new("Invalid SOA Record content attribute: #{self.content}") unless soa_fields.size == SOA_FIELDS.size

        soa_fields.each_with_index do |field_value, index|
            field_name  = SOA_FIELDS[index]
            field_value = field_value.try(:to_i) unless field_name == 'primary_ns' || field_name == 'contact'
            instance_variable_set("@#{field_name}", field_value)
            instance_variable_set("@#{field_name}_was", field_value)
        end

        update_serial if @serial.nil? || @serial.zero?
    end
end
