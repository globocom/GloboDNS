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

# = Text Record (TXT)
#
# Provides the ability to associate some text with a host or other name. The TXT
# record is used to define the Sender Policy Framework (SPF) information record 
# which may be used to validate legitimate email sources from a domain. The SPF 
# record while being increasing deployed is not (July 2004) a formal IETF RFC 
# standard.
# 
# Obtained from http://www.zytrax.com/books/dns/ch8/txt.html

class TXT < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::TXT
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
