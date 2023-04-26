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

class IpAddressValidator < ActiveModel::EachValidator
  include RecordPatterns

  def validate_each( record, attribute, value )
    return if record.generate?
    record.errors[ attribute ] << I18n.t(:message_attribute_must_be_ip) unless valid?( value )
  end

  def valid?( ip )
    begin
      ip = IPAddr.new ip
      if options[:ipv6]
        return ip.ipv6?
      else
        return ip.ipv4?
      end
    rescue Exception => e
      false
    end
  end
end
