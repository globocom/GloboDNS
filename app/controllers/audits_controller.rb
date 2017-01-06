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
        @audits = Audited::Adapters::ActiveRecord::Audit.includes(:user)

        # filtros dos logs
        if params[:audit_days] || params[:audit_hours] || params[:audit_mins]
            @audits = @audits.where('created_at >= :time_ago', :time_ago => Time.now - params[:audit_days].to_i.days - params[:audit_hours].to_i.hours - params[:audit_mins].to_i.minutes)
        end
        if params[:audit_action] 
            @audits = @audits.where(action: params[:audit_action]) unless params[:audit_action] == "all"
        end
        if params[:audit_user] && params[:audit_user] != ""
            user = User.where("login like :login", login: "%#{params[:audit_user]}%").first 
            user = User.where("email like :email", email: "%#{params[:audit_user]}%").first if user.nil?
            @audits = @audits.where(user: user)
        end
        if params[:audit_content] && params[:audit_content] != ""
            ids = []
            @audits.each do |a|
                if a.action == "update" and a['audited_changes'].keys.include? 'content'
                    a['audited_changes']['content'].each do |c|
                        ids.push(a.id) if c.include? params[:audit_content]
                    end
                else
                    ids.push(a.id) if a['audited_changes']['content'] == params[:audit_content]
                end
            end
            @audits = @audits.where({id: ids})
        end
        if params[:audit_record] && params[:audit_record] != ""
            ids = []
            @audits.where(auditable_type: "Record").each do |a|
                ids.push(a.id) if a['audited_changes']['name'] == params[:audit_record]
            end
            @audits = @audits.where({id: ids})
        end
        if params[:audit_record_type] && params[:audit_record_type] != ""
            ids = []
            @audits.where(auditable_type: "Record").each do |a|
                ids.push(a.id) if a['audited_changes']['type'] == params[:audit_record_type]
            end
            @audits = @audits.where({id: ids})
        end
        if params[:audit_domain] && params[:audit_domain] != ""
            ids = []
            domain_id = 0
            if domain = Domain.where(name: params[:audit_domain]).first
                # o dominio buscado ainda existe no banco de dados
                @audits.where(auditable_type: "Record").each do |a|
                    id = a['audited_changes']['domain_id'] || a.associated_id
                    ids.push(a.id) if id == domain.id
                end
                @audits.where(auditable_type: "Domain").each do |a|
                    if a.associated_id?
                        ids.push(a.id) if a.associated_id == domain.id
                    elsif !a['audited_changes']['name'].nil?
                        ids.push(a.id) if a['audited_changes']['name'] == params[:audit_domain]
                    else
                        ids.push(a.id) if Record.find(a.auditable_id).domain.id == domain.id
                    end
                end
            else
                # procura a id do dominio nos logs dos domains deletados
                deleted = Audited::Adapters::ActiveRecord::Audit.where(auditable_type: "Domain", action: "Destroy")
                deleted.each do |d|
                    if d['audited_changes']['name'] == params[:audit_domain]
                        domain_id = d.auditable_id
                        break
                    end
                end
                # o dominio buscado foi deletado
                if domain_id != 0
                    @audits.where(auditable_type: "Record").each do |a|
                        id = a['audited_changes']['domain_id'] || a.associated_id
                        ids.push(a.id) if id == domain_id
                    end
                    @audits.where(auditable_type: "Domain").each do |a|
                        if a.associated_id?
                            ids.push(a.id) if a.associated_id == domain_id
                        elsif !a['audited_changes']['name'].nil?
                            ids.push(a.id) if a['audited_changes']['name'] == params[:audit_domain]
                        else
                            ids.push(a.id) if Record.find(a.auditable_id).domain.id == domain_id
                        end
                    end
                # dominio nunca existiu
                else
                end
            end
            @audits = @audits.where({id: ids})
        end
        # fim dos filtros

        @audits = @audits.reorder('id DESC').paginate(:page => params[:page] || 1, :per_page => 20) if request.format.html? || request.format.js?
        respond_with(@audits) do |format|
            format.html { render :partial => 'list', :object => @audits, :as => :audits if request.xhr? }
        end
    end
end
