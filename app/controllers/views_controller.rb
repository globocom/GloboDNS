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

class ViewsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?

    def index
        @views = View.all
        @views = @views.paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
        @views = @views.where(name: params[:query]) if params[:query]
        respond_with(@views) do |format|
            format.html { render :partial => 'list', :object => @views, :as => :views if request.xhr? }
        end
    end

    def show
        @view = View.find(params[:id])
        respond_with(@view)
    end

    def new
        @view = View.new
        respond_with(@view)
    end

    def edit
        @view = View.find(params[:id])
        respond_with(@view)
    end

    def create
        @view = View.new(params[:view])
        @view.save

        respond_with(@view) do |format|
            format.html { render :status  => @view.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @view.valid? ? @view : 'errors' } if request.xhr?
        end
    end

    def update
        if params[:view] && params[:view][:password].blank? && params[:view][:password_confirmation].blank?
            params[:view].delete(:password)
            params[:view].delete(:password_confirmation)
        end
        @view = View.find(params[:id])
        @view.update_attributes(params[:view])

        respond_with(@view) do |format|
            format.html { render :status  => @view.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @view.valid? ? @view : 'errors' } if request.xhr?
        end
    end

    def destroy
        @view = View.find(params[:id])
        @view.destroy
        respond_with(@view) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end
end
