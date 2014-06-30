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

# Complement the functionality provided by the 'validation_scopes' plugin.
# We rely on the 'validation_scope :warning' construct to define validations
# that don't block model persistence. But the plugin doesn't add the warnings
# to the serialized forms (json & xml) of the resources where the validation
# scopes are defined.
#
# This model provides a half-baked solution to this. It overrides the 'as_json'
# and 'as_xml' methods, adding a 'warnings' property when appropriate.

module ModelSerializationWithWarnings
    extend ActiveSupport::Concern

    included do
        def as_json(options = nil)
            self.warnings.any? ? super.merge!('warnings' => self.warnings.as_json) : super
        end

        def to_xml(options = {})
            self.warnings.any? ? super(:methods => [:warnings]) : super
        end

        def becomes(klass)
            became = super(klass)
            became.instance_variable_set("@warnings", @warnings)
            became
        end
    end
end
