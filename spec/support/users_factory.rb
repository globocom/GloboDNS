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

Factory.define :admin, :class => User do |f|
  f.login 'admin'
  f.email 'admin@example.com'
  f.password 'secret'
  f.password_confirmation 'secret'
  f.confirmation_token nil
  f.confirmed_at Time.now
  f.admin true
end

Factory.define(:quentin, :class => User) do |f|
  f.login 'quentin'
  f.email 'quentin@example.com'
  f.password 'secret'
  f.password_confirmation 'secret'
  f.confirmation_token nil
  f.confirmed_at Time.now
end

Factory.define(:aaron, :class => User) do |f|
  f.login 'aaron'
  f.email 'aaron@example.com'
  f.password 'secret'
  f.password_confirmation 'secret'
  f.confirmation_token nil
  f.confirmed_at Time.now
end

Factory.define(:token_user, :class => User) do |f|
  f.login 'token'
  f.email 'token@example.com'
  f.password 'secret'
  f.password_confirmation 'secret'
  f.admin  true
  f.auth_tokens true
  f.confirmation_token nil
  f.confirmed_at Time.now
end

Factory.define(:api_client, :class => User) do |f|
  f.login 'api'
  f.email 'api@example.com'
  f.password 'secret'
  f.password_confirmation 'secret'
  f.admin true
  f.confirmation_token nil
  f.confirmed_at Time.now
end
