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

# See #MX

# = Mail Exchange Record (MX)
# Defined in RFC 1035. Specifies the name and relative preference of mail
# servers (mail exchangers in the DNS jargon) for the zone.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/mx.html
#
class MX < Record
    validates_numericality_of :prio, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 65535, :only_integer => true
    validates_with HostnameValidator, :attributes => :content
    validation_scope :warnings do |scope|
        scope.validate :validate_same_name_and_type   # validation_scopes doesn't support inheritance; we have to redefine this validation
        scope.validate :validate_indirect_local_cname
    end

    def supports_prio?
        true
    end

    def resolv_resource_class
        Resolv::DNS::Resource::IN::MX
    end

    def match_resolv_resource(resource)
        resource.preference == self.prio &&
        (resource.exchange.to_s == self.content.chomp('.') ||
         resource.exchange.to_s == (self.content + '.' + self.domain.name))
    end

    def validate_indirect_local_cname
        return if self.fqdn_content?

        cname = CNAME.where('domain_id' => self.domain_id, 'name' => self.content).first
        unless cname.nil? || cname.fqdn_content?
            self.warnings.add(:base, I18n.t('indirect_local_cname_mx', :scope => 'activerecord.errors.messages', :name => self.content, :replacement => cname.content))
        end
    end
end
