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

module BindTimeFormatHelper
  ::String.class_eval do
    def parse_bind_time_format
      value = self.to_s.clone
      sum   = 0

      while value.slice!(/^(\d+)([sSmMhHdDwW]|$)/)
        sum += case $2.downcase
        when  ''; $1.to_i.seconds
        when 's'; $1.to_i.seconds
        when 'm'; $1.to_i.minutes
        when 'h'; $1.to_i.hours
        when 'd'; $1.to_i.days
        when 'w'; $1.to_i.weeks
        else      nil
        end
      end

      value.size == 0 ? sum : nil
    end
  end

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    def validates_bind_time_format(*attr_names)
      # validates *args, :bind_time_format => true
      validates_with BindTimeFormatValidator, _merge_attributes(attr_names)

      attr_names.each do |attr_name|
        define_method "#{attr_name}_int" do
          parse_bind_time_format(attr_name)
        end
      end
    end
  end

  module InstanceMethods
    def parse_bind_time_format(attr)
      value = self.send(attr.to_sym)
      value.is_a?(String) ? value.parse_bind_time_format : value
    end
  end

  class BindTimeFormatValidator < ActiveModel::EachValidator
    MAX_INT = ((2 ** 31) - 1)

    def validate_each(record, attribute, value)
      return if value.nil? || value.blank?

      if value.is_a?(String)
        int_value = value.parse_bind_time_format
        record.errors.add(attribute) if int_value.nil? || (int_value.to_i < 0) || (int_value.to_i > MAX_INT)
      elsif value.is_a?(Numeric)
        record.errors.add(attribute) if (value.to_i < 0) || (value.to_i > MAX_INT)
      else
        record.errors.add(attribute)
      end
    end
  end
end
