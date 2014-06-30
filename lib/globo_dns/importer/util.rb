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

String.class_eval do
    def strip_quotes
        self.sub(/^['"]?(.*?)['"]?$/, '\1')
    end
end

Citrus::Match.class_eval do
    def delete_from(parent)
        captures.clear
        matches.clear
        puts "indeed! parent.matches includes it!" if parent.matches.include?(self)
        parent.matches.delete(self)
        parent.captures.each do |key, value|
            puts "indeed! parent.captures[#{key}] is it!" if value.object_id == self.object_id
            parent.captures[key] = value = nil if value.object_id == self.object_id
            puts "indeed! parent.captures[#{key}] includes it!" if value.is_a?(Array) && value.include?(self)
            parent.captures[key].delete(self)  if value.is_a?(Array) && value.include?(self)
        end
    end
end
