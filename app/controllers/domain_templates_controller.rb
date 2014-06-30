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

class DomainTemplatesController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?,              :except => [:show, :index]
    before_filter :admin_or_operator?, :only => [:show, :index]

    DEFAULT_PAGE_SIZE = 25

    def index
        @domain_templates = DomainTemplate.scoped
        @domain_templates = @domain_templates.includes(:record_templates).paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
        respond_with(@domain_templates) do |format|
            format.html { render :partial => 'list', :object => @domain_templates, :as => :domain_templates if request.xhr? }
        end
    end

    def show
        @domain_template = DomainTemplate.find(params[:id])
        unless request.xhr?
            @soa_record_template = @domain_template.record_templates.where('type  = ?', 'SOA').first
            @record_templates    = @domain_template.record_templates.where('type != ?', 'SOA').paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
        end
        respond_with(@domain_template)
    end

    def new
        @domain_template = DomainTemplate.new
        respond_with(@domain_template)
    end

    def edit
        @domain_template = DomainTemplate.find(params[:id])
        respond_with(@domain_template)
    end

    def create
        @domain_template = DomainTemplate.new(params[:domain_template])
        @domain_template.save
        Rails.logger.info "[controller] after save"

        respond_with(@domain_template) do |format|
            format.html { render :status  => @domain_template.valid? ? :ok              : :unprocessable_entity,
                                 :partial => @domain_template.valid? ? @domain_template : 'errors' } if request.xhr?
        end
    end

    def update
        @domain_template = DomainTemplate.find(params[:id])
        @domain_template.update_attributes(params[:domain_template])
        respond_with(@domain_template) do |format|
            format.html { render :status  => @domain_template.valid? ? :ok    : :unprocessable_entity,
                                 :partial => @domain_template.valid? ? 'form' : 'errors' } if request.xhr?
        end
    end

    def destroy
        @domain_template = DomainTemplate.find(params[:id])
        @domain_template.destroy
        respond_with(@domain_template)
    end
end
