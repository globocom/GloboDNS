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

class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += I18n.t(:message_user_activate_account)
  
    @body[:url]  = "http://YOURSITE/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += I18n.t(:message_user_activated)
    @body[:url]  = "http://YOURSITE/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "ADMINEMAIL"
      @subject     = "[YOURSITE] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
