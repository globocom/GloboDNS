class RecordTemplate < ActiveRecord::Base
    belongs_to :domain_template, :inverse_of => :record_templates

    # General validations
    validates_presence_of :domain_template, :name, :ttl
    validates_presence_of :record_type

    before_save           :build_content, :if => :soa?
    before_validation     :set_soa_name,  :if => :soa?
    before_validation     :set_serial,    :if => :soa?
    before_validation     :inherit_ttl
    after_initialize      :update_convenience_accessors
    validate              :validate_record_template

    scope :without_soa, where('record_type != ?', 'SOA')

    # attr_accessible :name, :record_type, :ttl, :prio, :content, :primary_ns, :contact, :refresh, :retry, :expire, :minimum

    # We need to cope with the SOA convenience
    SOA::SOA_FIELDS.each do |field|
        attr_accessor field
        attr_reader   field.to_s + '_was'
    end

    def self.record_types
        Record.record_types
    end

    def type
        self.record_type
    end

    # Hook into #reload
    def reload_with_content
        reload_without_content
        update_convenience_accessors
    end
    alias_method_chain :reload, :content

    # Convert this template record into a instance +record_type+ with the
    # attributes of the template copied over to the instance
    def build(domain_name = nil)
        # build_content if soa? # rebuild the 'content' attribute from the broken attributes ('primary_ns', 'contact', etc)

        klass       = self.record_type.constantize
        attr_names  = klass.accessible_attributes.to_a.any? ? klass.accessible_attributes : klass.column_names
        attr_names -= klass.protected_attributes.to_a
        attr_names -= ['content'] if soa?

        attrs = attr_names.inject(Hash.new) do |hash, attr_name|
            hash[attr_name] = self.send(attr_name.to_sym) if self.respond_to?(attr_name.to_sym)
            hash
        end
        hash

        record = klass.new(attrs)
        record.serial = 0 if soa? # overwrite 'serial' attribute of SOA records

        record
    end

    def soa?
        self.try(:record_type) == 'SOA'
    end

    # def content
    #     soa? ? build_content : self.content
    # end

    # manage TTL inheritance here
    def inherit_ttl
        self.ttl ||= self.domain_template.ttl if self.domain_template
    end

    # Manage SOA content
    def update_soa_content #:nodoc:
        self[:content] = content
    end

    # Here we perform some magic to inherit the validations from the "destination"
    # model without any duplication of rules. This allows us to simply extend the
    # appropriate record and gain those validations in the templates
    def validate_record_template #:nodoc:
        unless self.record_type.blank?
            record = build
            record.errors.each do |attr, message|
                # skip associations we don't have, validations we don't care about
                next if attr == :domain || attr == :name

                self.errors.add(attr, message)
            end unless record.valid?
        end
    end

    def to_partial_path
        case record_type
        when 'SOA'; "#{self.class.name.underscore.pluralize}/soa_record_template"
        else;       "#{self.class.name.underscore.pluralize}/record_template"
        end
    end

    private

    # update our convenience accessors when the object has changed
    def update_convenience_accessors
        return if !soa? || self.content.blank?

        soa_fields = self.content.split(/\s+/)
        raise Exception.new("Invalid SOA Record content attribute: #{self.content}") unless soa_fields.size == SOA::SOA_FIELDS.size

        soa_fields.each_with_index do |field_value, index|
            field_name  = SOA::SOA_FIELDS[index]
            field_value = field_value.try(:to_i) unless field_name == 'primary_ns' || field_name == 'contact'
            instance_variable_set("@#{field_name}", field_value)
            instance_variable_set("@#{field_name}_was", field_value)
        end
    end

    def set_soa_name
        self.name ||= '@'
    end
    
    def set_serial
        self.serial ||= 0
    end

    def build_content
        self.content = SOA::SOA_FIELDS.map { |f| instance_variable_get("@#{f}").to_s }.join(' ')
    end
end
