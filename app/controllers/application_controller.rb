class ApplicationController < ActionController::Base
    protect_from_forgery

    before_filter :authenticate_user!  # all pages require a login
    after_filter  :flash_headers

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

    def flash_headers
        return unless request.xhr?

        if flash[:error].present?
            response.headers['x-flash']      = flash[:error]
            response.headers['x-flash-type'] = 'error'
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

    def render_404
        respond_to do |format|
            format.html { render :status => :forbidden, :file => File.join(Rails.root, 'public', '404.html'), :layout => nil }
            format.json { render :status => :not_found, :json => { :error => 'NOT FOUND' } }
        end
    end
end
