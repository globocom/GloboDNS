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

class SearchController < ApplicationController

  def results
    if params[:q].chomp.blank?
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { render :status => 404, :json => { :error => "Missing 'q' parameter" } }
      end
    else
      @results = Domain.search(params[:q], params[:page], current_user)

      respond_to do |format|
        format.html do
          if @results.size == 1
            redirect_to domain_path(@results.pop)
          end
        end
        format.json do
          render :json => @results.to_json(:only => [:id, :name])
        end
      end
    end
  end

end
