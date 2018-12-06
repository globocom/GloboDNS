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

class RecordsController < ApplicationController
  include RecordsHelper

  respond_to :html, :json
  responders :flash

  before_filter :admin_or_operator?, :except => [:index, :show]

  DEFAULT_PAGE_SIZE = 25

  def index
    @records = Record.where(:domain_id => params[:domain_id])
    @records = @records.without_soa.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
    @records = @records.matching(params[:records_query]) if params[:records_query].present?
    @records = @records.matching(params[:query]) if params[:query].present? # when using api
    respond_with(@records) do |format|
      format.html {
      render :partial => 'list', :object => @records, :as => :records if request.xhr? }
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
    if should_increase_ttl?
      params[:record][:ttl] = 60 unless (params[:record][:ttl] and params[:record][:ttl].to_i < 60)
    end

    params[:record].each do |label, value|
      params[:record][label] = params[:record][label].to_s.gsub(/^[ \t]/,'') unless value.nil?
    end

    @record = params[:record][:type].constantize.new(params[:record])
    @record.domain_id = params[:domain_id]

    valid = (!@record.errors.any? and @record.valid?)

    ownership = true
    if GloboDns::Config::DOMAINS_OWNERSHIP
      unless current_user.admin?
        name_available = DomainOwnership::API.instance.get_domain_ownership_info(@record.url)[:group].nil?
        permission = @record.check_ownership(current_user)
        ownership = (name_available or permission)
      end
    end

    valid = (valid and ownership)

    if valid
      @record.save
      if GloboDns::Config::DOMAINS_OWNERSHIP
        @record.set_ownership(params[:sub_component], current_user)
      end
    end

    flash[:warning] = "#{@record.warnings.full_messages * '; '}" if @record.has_warnings?
    respond_with(@record.becomes(Record)) do |format|
      format.html { render :status  => valid ? :ok     : :unprocessable_entity,
                    :partial => valid ? @record : 'errors' } if request.xhr?
    end
  end

  def update
    if should_increase_ttl?
      params[:record][:ttl] = 60 unless (params[:record][:ttl] and params[:record][:ttl].to_i < 60)
    end

    params[:record].each do |label, value|
      params[:record][label] = params[:record][label].to_s.gsub(/^[ \t]/,'') unless value.nil?
    end

    @record = Record.find(params[:id])

    valid = (!@record.errors.any? and @record.valid?)

    ownership = true
    old_ownership_info = nil
    new_ownership_info = nil

    if GloboDns::Config::DOMAINS_OWNERSHIP
      unless current_user.admin?
        ownership = @record.check_ownership(current_user)
        name_changed = !(@record.name.eql? params[:record][:name])
        if name_changed
          old_ownership_info = DomainOwnership::API.instance.get_domain_ownership_info @record.url
          @record.name = params[:record][:name]
          new_ownership_info = DomainOwnership::API.instance.get_domain_ownership_info @record.url
          ownership = @record.check_ownership(current_user)
        end
      end
    end

    valid = (valid and ownership)

    if valid and GloboDns::Config::DOMAINS_OWNERSHIP
      @record.update_attributes(params[:record])
      @record.set_ownership(old_ownership_info[:sub_component_id], current_user) if name_changed and new_ownership_info[:group_id].nil?

    end

    flash[:warning] = "#{@record.warnings.full_messages * '; '}" if @record.has_warnings?
    respond_with(@record.becomes(Record)) do |format|
      format.html { render :status  => valid ? :ok     : :unprocessable_entity,
                    :partial => valid ? @record : 'errors' } if request.xhr?
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
    @response = @record.resolve if Record::testable_types.include? @record.type
    respond_to do |format|
      format.html { render :partial => 'resolve' } if request.xhr?
      # format.json { render :json => {'master' => @master_response, 'slave' => @slave_response}.to_json }
    end
  end
end
