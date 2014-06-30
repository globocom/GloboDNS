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

class RecordsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin_or_operator?, :except => [:index, :show]
    
    DEFAULT_PAGE_SIZE = 25

    def index
        @records = Record.where(:domain_id => params[:domain_id])
        @records = @records.without_soa.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
        @records = @records.matching(params[:query]) if params[:query].present?
        respond_with(@records) do |format|
            format.html { render :partial => 'list', :object => @records, :as => :records if request.xhr? }
        end
    end

    def show
        @record = Record.find(params[:id])
        respond_with(@record)
    end

    def new
        @record = Record.new(:domain_id => params[:domain_id])
        respond_with(@record)
    end

    def edit
        @record = Record.find(params[:id])
        respond_with(@record)
    end

    def create
        @record = params[:record][:type].constantize.new(params[:record])
        @record.domain_id = params[:domain_id]
        @record.save
        flash[:warning] = "#{@record.warnings.full_messages * '; '}" if @record.has_warnings?
        respond_with(@record.becomes(Record)) do |format|
            format.html { render :status  => @record.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @record.valid? ? @record : 'errors' } if request.xhr?
        end
    end

    def update
        @record = Record.find(params[:id])
        @record.update_attributes(params[:record])
        flash[:warning] = "#{@record.warnings.full_messages * '; '}" if @record.has_warnings?
        respond_with(@record.becomes(Record)) do |format|
            format.html { render :status  => @record.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @record.valid? ? @record : 'errors' } if request.xhr?
        end
    end

    def destroy
        @record = Record.find(params[:id])
        @record.destroy
        respond_with(@record) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end

    def resolve
        @record = Record.find(params[:id])
        @master_response, @slave_response = @record.resolve
        respond_to do |format|
            format.html { render :partial => 'resolve' } if request.xhr?
            format.json { render :json => {'master' => @master_response, 'slave' => @slave_response}.to_json }
        end
    end
end
