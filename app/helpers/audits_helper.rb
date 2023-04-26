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

module AuditsHelper

  def updated_changes (audit)
    if audit.action == "update"
      begin
        changes = audit.audited_changes
        record = Record.find(audit.auditable_id).attributes.except('created_at', 'updated_at')
        changes.keys.each do |key|
          record.delete(key)
        end
        changes.merge(record)
      rescue
        changes = audit.audited_changes
        audit_record = Audited::Adapters::ActiveRecord::Audit.where(auditable_id: audit.auditable_id, action: "create") || Audited::Adapters::ActiveRecord::Audit.where(auditable_id: audit.auditable_id, action: "destroy")
        unless audit_record.empty?
          record = audit_record.first['audited_changes']
          audit.audited_changes.merge(record)
        end
      end
    else
      audit.audited_changes
    end
  end

  def parenthesize( text )
    "(#{text})"
  end

  def link_to_domain_audit( audit )
    caption = "#{audit.version} #{audit.action} by "
    caption << audit_user( audit )
    link_to_function caption, "toggleDomainAudit(#{audit.id})"
  end

  def link_to_record_audit( audit )
    caption = audit.audited_changes['type']
    caption ||= (audit.auditable.nil? ? '[UNKNOWN]' : audit.auditable.class.to_s )
    unless audit.audited_changes['name'].nil?
      name = audit.audited_changes['name'].is_a?( Array ) ? audit.audited_changes['name'].pop : audit.audited_changes['name']
      caption += " (#{name})"
    end
    caption += " #{audit.version} #{audit.action} by "
    caption += audit_user( audit )
    link_to_function caption, "toggleRecordAudit(#{audit.id})"
  end

  def display_hash( hash )
    hash ||= {}
    hash.map do |k,v|
      if v.nil?
        nil # strip out non-values
      else
        if v.is_a?( Array )
          v = "From <em>#{v.shift}</em> to <em>#{v.shift}</em>"
        end

        "<em>#{k}</em>: #{v}"
      end
    end.compact.join('<br />')
  end

  def sort_audits_by_date( collection )
    collection.sort_by(&:created_at).reverse
  end

  def audit_user( audit )
    if audit.user.is_a?( User )
      audit.user.name
    else
      audit.username || 'UNKNOWN'
    end
  end

end
