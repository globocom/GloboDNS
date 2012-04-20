class ApplicationController < ActionController::Base
    protect_from_forgery

    before_filter :authenticate_user!  # all pages require a login
    after_filter  :flash_headers

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
end
