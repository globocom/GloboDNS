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

# = Signature Record (SIG)
#
# Signature record used in SIG(0) (RFC 2931) and TKEY (RFC 2930).[7] RFC 3755
# designated RRSIG as the replacement for SIG for use within DNSSEC.[7]

class SIG < Record
  def resolv_resource_class
    Resolv::DNS::Resource::IN::SIG
  end

  def match_resolv_resource(resource)
    resource.strings.join(' ') == self.content.chomp('.')
  end
end
