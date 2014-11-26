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

module GloboDns
class Resolver
    include GloboDns::Config
    include GloboDns::Util

    DEFAULT_PORT = 53

    def initialize(host, port)
        @host = host
        @port = port
    end

    MASTER = GloboDns::Resolver.new(Bind::Master::IPADDR, (Bind::Master::PORT rescue DEFAULT_PORT).to_i)
    SLAVES = Bind::Slaves.map do |slave|
        GloboDns::Resolver.new(slave::IPADDR, (slave::PORT  rescue DEFAULT_PORT).to_i)
    end

    def resolve(record)
        name      = Record::fqdn(record.name, record.domain.name)
        key_name  = record.domain.try(:query_key_name)
        key_value = record.domain.try(:query_key)

        args  = [Binaries::DIG, '@'+@host, '-p', @port.to_s, '-t', record.type]
        args += ['-y', "#{key_name}:#{key_value}"] if key_name && key_value
        args += [name, '+norecurse', '+noauthority', '+time=1'] # , '+short']

        exec!('dig', *args)
    end
end
end
