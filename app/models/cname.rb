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

# = Canonical Name Record (CNAME)
#
# A CNAME record maps an alias or nickname to the real or Canonical name which
# may lie outside the current zone. Canonical means expected or real name.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/cname.html

class CNAME < Record
  include RecordPatterns

  validates_with HostnameValidator, :attributes => :content

  def resolv_resource_class
    Resolv::DNS::Resource::IN::CNAME
  end

  def match_resolv_resource(resource)
    resource.name.to_s == self.content.chomp('.') ||
      resource.name.to_s == (self.content + '.' + self.domain.name)
  end

  def validate_name_format
    unless self.generate? || self.name.blank? || self.name == '@' || hostname?(self.name.gsub(/(^[*]\.)/,"")) || reverse_ipv4_fragment?(self.name) || reverse_ipv6_fragment?(self.name)
      self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
    end
  end
end
