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

class Notifier < ActionMailer::Base
    default :from    => "GloboDNS <globodns@globodns.com>",
            :to      => GloboDns::Config::MAIL_RECIPIENTS

    def import_successful(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_import_successful, :dns_group => GloboDns::Config::DNS_GROUP ,:env => Rails.env ))
    end

    def import_failed(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_import_failed, :dns_group => GloboDns::Config::DNS_GROUP ,:env => Rails.env ))
    end

    def export_successful(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_export_successful, :dns_group => GloboDns::Config::DNS_GROUP ,:env => Rails.env ))
    end

    def export_failed(message_body)
        @message_body = message_body
        mail(:subject => I18n.t(:mail_subject_export_failed, :dns_group => GloboDns::Config::DNS_GROUP ,:env => Rails.env ))
    end
end
