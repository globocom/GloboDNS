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

class ApplicationController < ActionController::Base
    HTTP_AUTH_TOKEN_HEADER = 'X-Auth-Token'

    protect_from_forgery with: :exception
    protect_from_forgery with: :null_session,
      if: Proc.new { |c| c.request.format =~ %r{application/json} }

    before_filter :check_auth

    before_filter :authenticate_user!
    after_filter  :flash_headers


    rescue_from Exception,                           :with => :render_500
    rescue_from ActiveRecord::RecordNotFound,        :with => :render_404
    rescue_from ActionController::RoutingError,      :with => :render_404
    rescue_from ActionController::UnknownController, :with => :render_404
    rescue_from AbstractController::ActionNotFound,  :with => :render_404

    helper_method :admin?, :operator?, :admin_or_operator?, :viewer?

    def new_session_path(scope)
        new_user_session_path
    end

    def admin?
        current_user.admin? or render_401
    end

    def operator?
        current_user.operator? or render_401
    end

    def admin_or_operator?
        (current_user.admin? || current_user.operator?) or render_401
    end

    def viewer?
        current_user.viewer? or render_401
    end

    def logout
        sign_out current_user
        path = new_user_session_url
        client_id = Rails.application.secrets.oauth_provider_client_id
        redirect_to "https://oauthprovider.com/logout"+ "?client_id=#{client_id}&redirect_uri=#{path}" # set providers logout uri
    end

    protected
    def flash_headers
        return unless request.xhr?

        if flash[:error].present?
            response.headers['x-flash']      = flash[:error]
            response.headers['x-flash-type'] = 'error'
        elsif flash[:warning].present?
            response.headers['x-flash']      = flash[:warning]
            response.headers['x-flash-type'] = 'warning'
        elsif flash[:notice].present?
            response.headers['x-flash']      = flash[:notice]
            response.headers['x-flash-type'] = 'notice'
        end

        flash.discard
    end

    def render_401
        respond_to do |format|
            format.html { render :status => :not_authorized, :file => File.join(Rails.root, 'public', '401.html'), :layout => nil }
            format.json { render :status => :forbidden,      :json => {:error => 'NOT AUTHORIZED'} }
        end
    end

    def render_403
        respond_to do |format|
            format.html { render :status => :forbidden, :file => File.join(Rails.root, 'public', '403.html'), :layout => nil }
            format.json { render :status => :forbidden, :json => {:error => 'FORBIDDEN'} }
        end
    end

    def render_404(exception)
        respond_to do |format|
            format.html { render :status => :not_found, :file => File.join(Rails.root, 'public', '404.html'), :layout => nil }
            format.json { render :status => :not_found, :json => { :error => 'NOT FOUND' } }
        end
    end

    def render_500(exception)
        logger.info "[Internal Server Error] exception: #{exception}\n#{exception.backtrace.join("\n")}"
        respond_to do |format|
            format.json { render :status => :internal_server_error, :json => { :error => exception.message, :backtrace => exception.backtrace } }
            format.html { raise(exception) }
        end
    end

    def navigation_format?
        request.format.html? || request.format.js?
    end


    private
    def login_present?
        if !params[:user].nil? 
            !params[:user][:email].blank? && !params[:user][:password].blank?
        else
            false
        end
    end

    def token_present?
        !request.env['HTTP_X_AUTH_TOKEN'].nil?
    end

    def check_auth
      if !(res = request.env['HTTP_AUTHORIZATION']).nil?
        type, token = res.split(' ')
        if !type.nil? && type.eql?('Bearer')
          resource = RestClient::Resource.new(OmniAuth::YourProvider::Client.client_options(Rails.env)[:site]) # set the OAut hProvider
          
          begin
            response = JSON.parse(resource['user'].get(:Authorization => "Bearer #{token}"))
            response['token'] = token
            user = User.from_api(response)
            logger.debug "User: #{user.inspect}"
            if user.active
              sign_in user, :store => false
            end
          rescue Exception => e
            logger.error e.message
          end
        end
      elsif login_present? && request.format == "text/x-json"
        user = User.find_by_email(params[:user][:email])
        if user && user.valid_password?(params[:user][:password])
            sign_in user
            respond_to do |format|
                format.json { render :status => :ok, :json => current_user.auth_json }
            end
        end
      elsif token_present?
        user = User.find_by_authentication_token(request.env['HTTP_X_AUTH_TOKEN'])
        if user
            sign_in user
        end
      end
    end
end
