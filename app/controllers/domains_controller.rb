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

class DomainsController < ApplicationController
  include GloboDns::Config

  respond_to :html, :json
  responders :flash

  before_filter :admin_or_operator?, :except => [:index, :show]


  DEFAULT_PAGE_SIZE = 25

  def index
    @ns = get_nameservers
    if GloboDns::Config::DOMAINS_OWNERSHIP
      users_permissions_info = DomainOwnership::API.instance.users_permissions_info(current_user)
      @sub_components = users_permissions_info[:sub_components]
    end
    session[:show_reverse_domains] = (params[:reverse] == 'true') if params.has_key?(:reverse)
    @domains = session[:show_reverse_domains] ? Domain.all : Domain.nonreverse
    @domains = @domains.includes(:records).paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
    if params[:query].present?
      params[:query].to_s.gsub(/^[ \t]/,'')
      @domains = @domains.matching(params[:query])
    end
    if request.path_parameters[:format] == 'json' and (defined? GloboDns::Config::ENABLE_VIEW and GloboDns::Config::ENABLE_VIEW == true)
      if params[:view]
        view = View.where(name: params[:view]).first
        if view.nil? and params[:view] != "all"
          @domains = nil
        else
          params[:view_id] = (params[:view] == "all"? "all" : view.id)
        end
      else
        params[:view_id] = View.where(name: "default").first.id
      end
    end
    @domains = @domains.where(view_id: params[:view_id]) if params[:view_id] and params[:view_id] != '' and params[:view_id] != 'all'
    respond_with(@domains) do |format|
      format.html { render :partial => 'list', :object => @domains, :as => :domains if request.xhr? }
    end
  end

  def show
    @domain = Domain.find(params[:id])
    if GloboDns::Config::DOMAINS_OWNERSHIP
      users_permissions_info = DomainOwnership::API.instance.users_permissions_info(current_user)
      @sub_components = users_permissions_info[:sub_components]
      @domain_ownership_info = DomainOwnership::API.instance.get_domain_ownership_info(@domain.name)
    end
    query    = params[:records_query].blank? ? nil : params[:records_query].gsub("%","*")
    if query.nil?
      @records = @domain.records.without_soa.paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
    else
      @records = @domain.records.without_soa.matching(params[:records_query]).paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
    end
    @sibling = @domain.sibling if @domain.sibling
    @sibling_records = @sibling.records.without_soa.paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE) if @sibling
    respond_with(@domain)
  end

  def new
    @domain = Domain.new
    respond_with(@domain)
  end

  def edit
    @domain = Domain.find(params[:id])
    respond_with(@domain)
  end

  def create
    domain_template_in_params = false
    domain_view_in_params = false

    params[:domain].each do |label, value|
      params[:domain][label] = params[:domain][label].to_s.gsub(/^[ \t]/,'')  unless value.nil?
    end


    if params[:domain][:domain_template_id].present? || params[:domain][:domain_template_name].present?
      domain_template_in_params = true
      @domain_template   = DomainTemplate.find(params[:domain][:domain_template_id])   if params[:domain][:domain_template_id]
      @domain_template ||= DomainTemplate.where('name' => params[:domain][:domain_template_name]).first if params[:domain][:domain_template_name]
    end
    if params[:domain][:domain_view_id].present? || params[:domain][:domain_view_name].present?
      domain_view_in_params = true
      @domain_view   = View.where('id'   => params[:domain][:domain_view_id]).first   if params[:domain][:domain_view_id]
      @domain_view ||= View.where('name' => params[:domain][:domain_view_name]).first if params[:domain][:domain_view_name]
    end
    if @domain_template
      @domain = @domain_template.build(params[:domain][:name])
    else
      @domain = Domain.new(params[:domain].except(:domain_template_id, :domain_template_name))
    end

    if @domain_view
      @domain.view = @domain_view
    end

    if domain_template_in_params && !@domain_template
      @domain.errors.add(:domain_template, 'Domain Template not found')
    end
    if domain_view_in_params && !@domain_view
      @domain.errors.add(:domain_view, 'Domain view not found')
    end

    # if 'uses_view' is set as true at 'globodns.yml', forces use default view when saving
    if defined? GloboDns::Config::ENABLE_VIEW and GloboDns::Config::ENABLE_VIEW == true
      @domain.view = View.default unless @domain.view
    end

    if @domain.export_to
      @domain.export_to = JSON.parse(params[:domain][:export_to]) - [""]
      @domain.export_to = nil if @domain.export_to.empty?
    end

    valid = (!@domain.errors.any? and @domain.valid?)

    ownership = true
    if GloboDns::Config::DOMAINS_OWNERSHIP
      unless current_user.admin?
        name_available = DomainOwnership::API.instance.get_domain_ownership_info(@domain.name)[:group].nil?
        permission = @domain.check_ownership(current_user)
        ownership = name_available or permission
      end
    end

    valid = (valid and ownership)

    if valid
      @domain.save
      if GloboDns::Config::DOMAINS_OWNERSHIP
          @domain.save
          @domain.set_ownership(params[:sub_component], current_user)
          @domain.records.each do |record|
            record.set_ownership(params[:sub_component], current_user)
        end
    end
    # flash[:warning] = "#{@domain.warnings.full_messages * '; '}" if @domain.has_warnings? && navigation_format?

    respond_with(@domain) do |format|
      format.html { render :status  => valid ? :ok     : :unprocessable_entity,
                    :partial => valid ? @domain : 'errors' } if request.xhr?
    end
  end

  def update
    params[:domain].each do |label, value|
      params[:domain][label] = params[:domain][label].to_s.gsub(/^[ \t]/,'') unless (value.nil? or label == 'notes')
    end

    @domain = Domain.find(params[:id])
    Rails.logger.info @domain

 

    valid = (!@domain.errors.any?)

    @domain.update_attributes(params[:domain]) if valid
    # flash[:warning] = "#{@domain.warnings.full_messages * '; '}" if @domain.has_warnings? && navigation_format?

    respond_with(@domain) do |format|
      format.html { render :status  => valid ? :ok     : :unprocessable_entity,
                    :partial => valid ? 'form'  : 'errors',
                    :object  => @domain, :as => :domain } if request.xhr?
    end
  end

  def destroy
    @domain = Domain.find(params[:id])
    @domain.destroy
    respond_with(@domain)
  end

  def update_domain_owner
    @domain = Domain.find(params[:id])

    if GloboDns::Config::DOMAINS_OWNERSHIP
      users_permissions_info = DomainOwnership::API.instance.users_permissions_info(current_user)
      @sub_components = users_permissions_info[:sub_components]
      @domain_ownership_info = DomainOwnership::API.instance.get_domain_ownership_info(@domain.name)

      if @domain_ownership_info[:id].nil?
        DomainOwnership::API.instance.post_domain_ownership_info(@domain.name, params[:sub_component], "domain", current_user)
      else
        DomainOwnership::API.instance.patch_domain_ownership_info(@domain_ownership_info[:id], @domain.name, params[:sub_component], "domain")
      end

      @domain_ownership_info = DomainOwnership::API.instance.get_domain_ownership_info(@domain.name)

      @domain = Domain.find(params[:id])
      respond_to do |format|
        format.html { render :partial => 'owner_info' }
      end
    else
    end
  end
  end
  end
