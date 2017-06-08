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

# = DNSSEC signature Record (RRSIG)
#
# The RRSIG RR is part of the DNSSEC (DNSSEC.bis) standard. Each RRset in a
# signed zone will have an RRSIG RR containing a digest of the RRset created
# using a DNSKEY RR Zone Signing Key (ZSK). RRSIG RRs are unique in that they do
# not form RRsets - were this not so recursive signing would occur! RRSIG RRs
# are automatically created using the dnssec-signzone utility supplied with
# BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/rrsig.html

class RRSIG < Record
  def resolv_resource_class
    Resolv::DNS::Resource::IN::RRSIG
  end

  def match_resolv_resource(resource)
    resource.strings.join(' ') == self.content.chomp('.')
  end
end
