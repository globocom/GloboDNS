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

# = DNSKEY Record (NSKEY)
#
# The DNSKEY RR is part of the DNSSEC (DNSSEC.bis) standard. DNSKEY RRs contain
# the public key (of an asymmetric encryption algorithm) used in zone signing
# operations. Public keys used for other functions are defined using a KEY RR.
# DNSKEY RRs may be either a Zone Signing Key (ZSK) or a Key Signing Key (KSK).
# The DNSKEY RR is created using the dnssec-keygen utility supplied with BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/dskey.html

class DNSKEY < Record
  def resolv_resource_class
    Resolv::DNS::Resource::IN::DNSKEY
  end

  def match_resolv_resource(resource)
    resource.strings.join(' ') == self.content.chomp('.')
  end
end
