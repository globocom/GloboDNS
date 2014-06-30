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

module SyslogHelper
    def syslog_audit(audit)
        msg  = "[#{audit.auditable_type.downcase}:#{audit.action}:#{audit.auditable_id}]"
        msg << "[#{audit.associated_type.downcase}:#{audit.associated_id}]" if audit.associated_type
        msg << "[user:#{audit.user.login}]"                                 if audit.user && audit.user.login
        msg << "[from:#{audit.remote_address}]"                             if audit.remote_address
        msg << " #{audit.audited_changes.to_json}"
        msg << " (#{audit.comment})"                                        if audit.comment

        Rails.syslogger.info msg
    end

    def syslog_info(message)
        Rails.syslogger.info "[INFO] #{message}"
    end

    def syslog_error(message)
        Rails.syslogger.error "[ERROR] #{message}"
    end
end
