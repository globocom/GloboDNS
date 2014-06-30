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

ActiveRecord::Base.class_eval do
    def self.define_enum(attribute, symbols, values = nil)
        define_method((attribute.to_s + '_str').to_sym) { self.class.const_get(attribute.to_s.pluralize.upcase.to_sym)[self.send(attribute)] }

        values ||= symbols.collect{|symbol| symbol.to_s[0]}

        symbols.zip(values).inject(Hash.new) do |hash, (enum_sym, enum_value)|
            enum_str    = enum_sym.to_s
            value       = enum_value
            hash[value] = enum_str

            const_set(enum_sym, value)
            define_method(enum_str.downcase + '?') { self.send(attribute) == value }
            define_method(enum_str.downcase + '!') { self.send((attribute.to_s + '=').to_sym, value) }

            hash
        end.freeze
    end
end
