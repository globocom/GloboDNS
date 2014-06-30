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

class CreateDomains < ActiveRecord::Migration
    def self.up
        create_table :domains, :force => true do |t|
            t.integer :user_id
            t.string  :name
            t.string  :master
            t.integer :last_check
            t.string  :type,           :null => false
            t.integer :notified_serial
            t.string  :account
            t.integer :ttl,            :null => false
            t.text    :notes
            t.timestamps
        end

        add_index :domains, :name
    end

    def self.down
        drop_table :domains
    end
end
