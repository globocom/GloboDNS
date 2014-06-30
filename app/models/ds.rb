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

# = DS Record (DS)
#
# The Delegated Signer RR is part of the DNSSEC (DNSSEC.bis) standard. It
# appears at the point of delegation in the parent zone and contains a digest of
# the DNSKEY RR used as either a Zone Signing Key (ZSK) or a Key Signing Key
# (KSK). It is used to authenticate the chain of trust from the parent to the
# child zone. The DS RR is optionally created using the dnssec-signzone utility
# supplied with BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/ds.html

class DS < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::DS
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
