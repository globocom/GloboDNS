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

# see https://github.com/rails/rails/pull/3023

ActiveRecord::Base.class_eval do
    # Returns an instance of the specified +klass+ with the attributes of the
    # current record. This is mostly useful in relation to single-table
    # inheritance structures where you want a subclass to appear as the
    # superclass. This can be used along with record identification in
    # Action Pack to allow, say, <tt>Client < Company</tt> to do something
    # like render <tt>:partial => @client.becomes(Company)</tt> to render that
    # instance using the companies/company partial instead of clients/client.
    #
    # Note: The new instance will share a link to the same attributes as the original class.
    # So any change to the attributes in either instance will affect the other.
    def becomes(klass)
        became = klass.new
        became.instance_variable_set("@attributes", @attributes)
        became.instance_variable_set("@attributes_cache", @attributes_cache)
        became.instance_variable_set("@new_record", new_record?)
        became.instance_variable_set("@destroyed", destroyed?)
        became.instance_variable_set("@errors", errors)
        became
    end

    # Wrapper around +becomes+ that also changes the instance's sti column value.
    # This is especially useful if you want to persist the changed class in your
    # database.
    #
    # Note: The old instance's sti column value will be changed too, as both objects
    # share the same set of attributes.
    def becomes!(klass)
        became = becomes(klass)
        became.send("#{klass.inheritance_column}=", klass.sti_name) unless self.class.descends_from_active_record?
        became
    end
end
