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

# = Name Server Record (PTR)
#
# Pointer records are the opposite of A and AAAA RRs and are used in Reverse Map
# zone files to map an IP address (IPv4 or IPv6) to a host name.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/ptr.html

class PTR < Record
  include RecordPatterns

  validates_with HostnameValidator, :attributes => :content

  def resolv_resource_class
    Resolv::DNS::Resource::IN::PTR
  end

  def match_resolv_resource(resource)
    resource.name.to_s == self.content.chomp('.') ||
      resource.name.to_s == (self.content + '.' + self.domain.name)
  end

  def validate_name_format
    unless self.name.blank? || self.name == '@' || reverse_ipv4_fragment?(self.name) || reverse_ipv6_fragment?(self.name)
      self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
    end
  end
end
