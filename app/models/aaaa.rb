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

# = IPv6 Address Record (AAAA)
#
# The current IETF recommendation is to use AAAA (Quad A) RR for forward mapping
# and PTR RRs for reverse mapping when defining IPv6 networks. The IPv6 AAAA RR
# is defined in RFC 3596. RFC 3363 changed the status of the A6 RR (defined in
# RFC 2874 from a PROPOSED STANDARD to EXPERIMENTAL due primarily to performance
# and operational concerns.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/aaaa.html

class AAAA < Record
  validates_with IpAddressValidator, :attributes => :content, :ipv6 => true

  def resolv_resource_class
    Resolv::DNS::Resource::IN::AAAA
  end

  def match_resolv_resource(resource)
    resource.address.to_s == self.content
  end
end
