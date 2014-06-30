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

# = Name Server Record (NS)
#
# Defined in RFC 1035. NS RRs appear in two places. Within the zone file, in
# which case they are authoritative records for the zone's name servers. At the
# point of delegation for either a subdomain of the zone or in the zone's
# parent. Thus the zone example.com's parent zone (.com) will contain
# non-authoritative NS RRs for the zone example.com at its point of delegation
# and subdomain.example.com will have non-authoritative NS RSS in the zone
# example.com at its point of delegation. NS RRs at the point of delegation are
# never authoritative only NS RRs for the zone are regarded as authoritative.
# While this may look a fairly trivial point, is has important implications for
# DNSSEC.
#
# NS RRs are required because DNS queries respond with an authority section
# listing all the authoritative name servers, for sub-domains or queries to the
# zones parent where they are required to allow referral to take place.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/ns.html

class NS < Record
    include RecordPatterns

    validates_with HostnameValidator, :attributes => :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::NS
    end

    def match_resolv_resource(resource)
        resource.name.to_s == self.content.chomp('.') ||
        resource.name.to_s == (self.content + '.' + self.domain.name)
    end

    def validate_name_format
        unless self.name.blank? || self.name == '@' || hostname?(self.name) || reverse_ipv4_fragment?(self.name) || reverse_ipv6_fragment?(self.name)
            self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
        end
    end
end
