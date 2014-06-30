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

# = Text Record (SPF)
#
# In computing, Sender Policy Framework (SPF) allows software to identify
# messages that are or are not authorized to use the domain name in the SMTP
# HELO and MAIL FROM (Return-Path) commands, based on information published in a
# sender policy of the domain owner. Forged return paths are common in e-mail
# spam and result in backscatter. SPF is defined in RFC 4408
#
# Obtained from http://en.wikipedia.org/wiki/Sender_Policy_Framework

class SPF < Record
end
