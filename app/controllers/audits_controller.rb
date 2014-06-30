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

class AuditsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin_or_operator?

    def index
        @audits = Audited::Adapters::ActiveRecord::Audit.includes(:user).reorder('id DESC').limit(20)
        @audits = @audits.paginate(:page => params[:page] || 1, :per_page => 20) if request.format.html? || request.format.js?
        respond_with(@audits) do |format|
            format.html { render :partial => 'list', :object => @audits, :as => :audits if request.xhr? }
        end
    end
end
