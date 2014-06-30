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

# = Service Record (SRV)
#
# An SRV record or Service record is a category of data in the Internet Domain
# Name System specifying information on available services. It is defined in
# RFC 2782. Newer internet protocols such as SIP and XMPP often require SRV
# support from clients.
#
# Obtained from http://en.wikipedia.org/wiki/SRV_record
# 
# See also http://www.zytrax.com/books/dns/ch8/srv.html

class SRV < Record
    # validates_numericality_of :prio, :greater_than_or_equal_to => 0

    # We support priorities
    # def supports_prio?
    #   true
    # end

    def resolv_resource_class
        Resolv::DNS::Resource::IN::SRV
    end

    def match_resolv_resource(resource)
        # TODO: break down SRV records into multiple attributes?
        "#{resource.priority} #{resource.weight} #{resources.port} #{resource.target}" == self.content.chomp('.')
    end
end
