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

    before_filter :set_token_param_from_http_headers
    before_filter :authenticate_user!  # all pages require a login
    before_filter :authenticate_user_from_token!
    after_filter  :flash_headers

    protect_from_forgery

    rescue_from Exception,                           :with => :render_500
    rescue_from ActiveRecord::RecordNotFound,        :with => :render_404
    rescue_from ActionController::RoutingError,      :with => :render_404
    rescue_from ActionController::UnknownController, :with => :render_404
    rescue_from AbstractController::ActionNotFound,  :with => :render_404

    helper_method :admin?, :operator?, :admin_or_operator?, :viewer?

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

    protected

    def set_token_param_from_http_headers
        params[:auth_token] = request.headers[HTTP_AUTH_TOKEN_HEADER] if params[:auth_token].blank? && request.headers[HTTP_AUTH_TOKEN_HEADER].present?
    end

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
    def authenticate_user_from_token!
        user_token = params[:user_token].presence
        user       = user_token && User.find_by_authentication_token(user_token.to_s)

        if user
          sign_in user
        end
    end
end
