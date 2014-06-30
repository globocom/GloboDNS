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

Factory.define(:zone_template, :class => ZoneTemplate) do |f|
  f.name 'East Coast Data Center'
  f.ttl 86400
end

Factory.define(:template_soa, :class => RecordTemplate) do |f|
  f.ttl 86400
  f.record_type 'SOA'
  #f.content 'ns1.%ZONE% admin@%ZONE% 0 10800 7200 604800 3600'
  f.primary_ns 'ns1.%ZONE%'
  f.contact 'admin@example.com'
  f.refresh 10800
  f.retry 7200
  f.expire 604800
  f.minimum 3600
end

Factory.define(:template_ns, :class => RecordTemplate) do |f|
  f.ttl 86400
  f.record_type 'NS'
  f.content 'ns1.%ZONE%'
end

Factory.define(:template_ns_a, :class => RecordTemplate) do |f|
  f.ttl 86400
  f.record_type 'A'
  f.name 'ns1.%ZONE%'
  f.content '10.0.0.1'
end

Factory.define(:template_cname, :class => RecordTemplate) do |f|
  f.ttl 86400
  f.record_type 'CNAME'
  f.name '%ZONE%'
  f.content 'some.cname.org'
end

Factory.define(:template_mx, :class => RecordTemplate) do |f|
  f.ttl 86400
  f.record_type 'MX'
  f.content 'mail.%ZONE%'
  f.prio 10
end
