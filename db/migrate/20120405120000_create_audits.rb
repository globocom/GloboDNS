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

class CreateAudits < ActiveRecord::Migration
    def self.up
        create_table :audits, :force => true do |t|
            t.integer  :auditable_id
            t.string   :auditable_type
            t.integer  :associated_id
            t.string   :associated_type
            t.integer  :user_id
            t.string   :user_type
            t.string   :username
            t.string   :action
            t.text     :audited_changes
            t.integer  :version, :default => 0
            t.string   :comment
            t.string   :remote_address
            t.datetime :created_at
        end

        add_index :audits, [:auditable_id, :auditable_type],   :name => 'auditable_index'
        add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
        add_index :audits, [:user_id, :user_type],             :name => 'user_index'
        add_index :audits, :created_at  
    end

    def self.down
        drop_table :audits
    end
end
