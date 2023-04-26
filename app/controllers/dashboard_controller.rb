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

require 'domain_ownership'

class DashboardController < ApplicationController
  include GloboDns::Config

  def index
    @ns = get_nameservers
    if GloboDns::Config::DOMAINS_OWNERSHIP
      users_permissions_info = DomainOwnership::API.instance.users_permissions_info(current_user)
      @sub_components = users_permissions_info[:sub_components]
    end
    @latest_domains = Domain.nonreverse.reorder('created_at DESC').limit(5)
  end
end
