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

class ReportsController < ApplicationController

  before_filter do
    unless current_user.admin?
      redirect_to root_url
    end
  end

  # search for a specific user
  def index
    @users = User.where(:admin => false).paginate(:page => params[:page])
    @total_domains  = Domain.count
    @system_domains = Domain.where('user_id IS NULL').count
  end

  def results
    if params[:q].chomp.blank?
      redirect_to reports_path
    else
      @results = User.search(params[:q], params[:page])
    end
  end

  def view
    @user = User.find(params[:id])
  end
end
