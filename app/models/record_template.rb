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

class RecordTemplate < ActiveRecord::Base
  belongs_to :domain_template, :inverse_of => :record_templates

  self.inheritance_column = '__unknown__' # don't use "type" as inheritance column

  # General validations
  validates_presence_of :domain_template, :name
  validates_presence_of :type

  attr_protected :domain_template_id
  attr_accessible :name, :type, :content, :ttl, :prio, :weight, :port, :domain_template, :tag

  protected_attributes.delete('type') # 'type' is a special inheritance column use by Rails and not accessible by default;

  before_validation     :build_content, :if => :soa?
  before_validation     :set_soa_name,  :if => :soa?
  before_validation     :set_serial,    :if => :soa?
  after_initialize      :update_convenience_accessors
  validate              :validate_record_template

  scope :without_soa, ->{where('type != ?', 'SOA')}

  # We need to cope with the SOA convenience
  SOA::SOA_FIELDS.each do |field|
    attr_accessor field
    attr_reader   field.to_s + '_was'
  end

  def self.record_types
    Record.record_types
  end

  # hook into #reload
  def reload_with_content
    reload_without_content
    update_convenience_accessors
  end
  alias_method_chain :reload, :content

  # Convert this template record into a instance +type+ with the
  # attributes of the template copied over to the instance
  def build(domain_name = nil)
    klass       = self.type.constantize
    attr_names  = klass.accessible_attributes.to_a.any? ? klass.accessible_attributes : klass.column_names
    attr_names -= klass.protected_attributes.to_a
    attr_names -= ['content'] if soa?

    attrs = attr_names.inject(Hash.new) do |hash, attr_name|
      if self.respond_to?(attr_name.to_sym)
        value = self.send(attr_name.to_sym)
        value = value.gsub('%ZONE%', domain_name) if domain_name && value.is_a?(String)
        hash[attr_name] = value
      end
      hash
    end
    hash

    record = klass.new(attrs)
    record.serial = 0 if soa? # overwrite 'serial' attribute of SOA records

    record
  end

  def soa?
    self.type == 'SOA'
  end

  def update(params)
    if soa?
      params.each do |value|
        field_name  = value[0]
        field_value = value[1]
        field_value = field_value.try(:to_i) unless field_name == 'primary_ns' || field_name == 'contact'
        instance_variable_set("@#{field_name}", field_value)
      end
    end
    self.update_attributes(params)
  end

  # Here we perform some magic to inherit the validations from the "destination"
  # model without any duplication of rules. This allows us to simply extend the
  # appropriate record and gain those validations in the templates
  def validate_record_template #:nodoc:
    unless self.type.blank?
      record = build
      record.errors.each do |attr, message|
        # skip associations we don't have, validations we don't care about
        next if attr == :domain || attr == :name

        self.errors.add(attr, message)
      end unless record.valid?
    end
  end

  def to_partial_path
    case type
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
