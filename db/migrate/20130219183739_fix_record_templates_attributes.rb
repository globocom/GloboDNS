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

class FixRecordTemplatesAttributes < ActiveRecord::Migration
    def up
        change_table 'record_templates' do |t|
            t.rename 'record_type', 'type'
            t.change 'content', :string, :limit => 4096, :null => false
            t.change 'ttl',     :string,                 :null => true
        end
    end

    def down
        change_table 'record_templates' do |t|
            t.rename 'type', 'record_type'
            t.change 'content', :string, :limit => 255, :null => false
            t.change 'ttl',     :string,                :null => false
        end
    end
end
