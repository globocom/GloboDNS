class RecordTemplate < ActiveRecord::Base
  belongs_to :zone_template

  # General validations
  validates_presence_of :zone_template_id, :name
  validates_associated  :zone_template
  validates_presence_of :record_type

  before_save       :update_soa_content
  before_validation :inherit_ttl
  after_initialize  :update_convenience_accessors
  validate          :validate_record_template

  attr_accessible :name, :record_type, :content, :ttl, :prio

  # We need to cope with the SOA convenience
  SOA::SOA_FIELDS.each do |f|
    attr_accessor f
  end

  def self.record_types
    Record.record_types
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
    klass       = self.record_type.constantize
    attr_names  = klass.accessible_attributes.to_a.any? ? klass.accessible_attributes : klass.column_names
    attr_names -= klass.protected_attributes.to_a

    attrs = self.attributes.slice(*attr_names)
    if domain_name
      attrs.each do |name, value|
        attrs[name] = value.gsub('%ZONE%', domain_name) if value.is_a?(String)
      end
    end

    record = klass.new(attrs)
    record.serial = 0 if record.is_a?(SOA) # overwrite 'serial' attribute of SOA records

    record
  end

  def soa?
    self.record_type == 'SOA'
  end

  def content
    soa? ? SOA::SOA_FIELDS.map{ |f| instance_variable_get("@#{f}") || 0 }.join(' ') : self[:content]
  end

  # Manage TTL inheritance here
  def inherit_ttl
    unless self.zone_template_id.nil?
      self.ttl ||= self.zone_template.ttl
    end
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
      record.errors.each do |k,v|
        # skip associations we don't have, validations we don't care about
        next if k == :domain_id || k == :name

        self.errors.add( k, v )
      end unless record.valid?
    end
  end

  private

  # Update our convenience accessors when the object has changed
  def update_convenience_accessors
    return unless self.record_type == 'SOA'

    # Setup our convenience values
    @primary_ns, @contact, @serial, @refresh, @retry, @expire, @minimum =
      self[:content].split(/\s+/) unless self[:content].blank?
    %w{ serial refresh retry expire minimum }.each do |i|
      value = instance_variable_get("@#{i}")
      value = value.to_i unless value.nil?
      send("#{i}=", value )
    end
  end
end
