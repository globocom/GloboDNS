# = Start of Authority Record
# Defined in RFC 1035. The SOA defines global parameters for the zone (domain).
# There is only one SOA record allowed in a zone file.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/soa.html

class SOA < Record

    validates_presence_of     :primary_ns, :content, :serial, :refresh, :retry, :expire, :minimum
    validates_numericality_of :serial, :refresh, :retry, :expire, :allow_blank => true, :greater_than_or_equal_to => 0
    validates_numericality_of :minimum, :allow_blank => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10800
    validates_uniqueness_of   :domain_id, :on => :update
    validates                 :contact, :presence => true, :hostname => true
    validates                 :name,    :presence => true, :hostname => true

    # before_validation :update_serial
    before_validation :set_initial_serial, :on => :create
    before_validation :set_name
    before_validation :set_content
    after_initialize  :update_convenience_accessors

    attr_accessible :name, :ttl, :prio, :content, :primary_ns, :contact, :refresh, :retry, :expire, :minimum

    # the portions of the +content+ column that make up our SOA fields
    SOA_FIELDS = %w{primary_ns contact serial refresh retry expire minimum}

    # this allows us to have these convenience attributes act like any other
    # column in terms of validations
    SOA_FIELDS.each do |soa_entry|
        attr_accessor soa_entry
        attr_reader   soa_entry + '_was'
        define_method "#{soa_entry}_before_type_cast" do
            instance_variable_get("@#{soa_entry}")
        end
    end

    # hook into #reload
    def reload_with_content
        reload_without_content
        update_convenience_accessors
    end
    alias_method_chain :reload, :content

    def set_initial_serial
        self.serial = 0
    end

    # def update_serial
    #     update_serial! if self.new_record? || self.changed?
    # end
    #
    # updates the serial number to the next logical one. Format of the generated
    # serial is YYYYMMDDNN, where NN is the number of the change for the day
    def update_serial(save = false)
        current_date = Time.now.strftime('%Y%m%d')
        if self.serial.to_s.start_with?(current_date)
            self.serial += 1
        else
            self.serial = (current_date + '00').to_i
        end
        if save
            set_content
            self.transaction do
                self.update_column(:content, self.content)
            end
        end
    end

    def set_content
        self.content = SOA_FIELDS.map { |f| instance_variable_get("@#{f}").to_s  }.join(' ')
    end

    def set_name
        self.name ||= '@'
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

    # update our convenience accessors when the object has changed
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
        # update_serial if @serial.nil? || @serial.zero?
    end
end
