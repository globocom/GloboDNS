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

class DomainTemplate < ActiveRecord::Base
  has_many :record_templates, :dependent => :destroy, :inverse_of => :domain_template
  has_one  :soa_record_template,  -> {where(type: 'SOA')}, :class_name => 'RecordTemplate', :inverse_of => :domain_template
  # has_one  :soa_record_template, :class_name => 'RecordTemplate', :conditions => { 'type' => 'SOA' }, :inverse_of => :domain_template

  belongs_to :view

  validates_presence_of     :name
  validates_uniqueness_of   :name
  validates_presence_of     :ttl
  validates_numericality_of :ttl
  validates_associated      :soa_record_template
  attr_accessible           :id, :name, :ttl, :view_id, :primary_ns, :contact, :refresh, :retry, :expire, :minimum

  after_create              :create_soa_record_template

  SOA::SOA_FIELDS.each do |field|
    delegate field.to_sym, (field.to_s + '=').to_sym, :to => :soa_record_template
  end

  scope :with_soa, ->{joins(:record_templates).where('record_templates.type = ?', 'SOA')}
  default_scope {order('name')}

  def soa_record_template
    super || (self.soa_record_template = RecordTemplate.new('type' => 'SOA').tap{ |soa|
                if self.new_record?
                  soa.domain_template = self
                else
                  soa.domain_template_id = self.id
                end
    })
  end

  # Build a new domain using +self+ as a template. +domain+ should be valid domain
  # name.
  #
  # This method will throw exceptions as it encounters errors, and will use a
  # transaction to complete/rollback the operation.
  def build(domain_name)
    domain = Domain.new(:name           => domain_name,
                        :ttl            => self.ttl,
                        :authority_type => Domain::MASTER)

    record_templates.dup.each do |template|
      record = template.build(domain_name)

      domain.records   << record
      domain.soa_record = record if record.is_a?(SOA)
    end

    domain.view_id = self.view_id if self.view_id

    domain
  end

  def create_soa_record_template
    soa_record_template.save or raise "[ERROR] unable to save SOA record template(#{soa_record_template.errors.full_messages})"
  end
end
