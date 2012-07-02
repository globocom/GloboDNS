class AuditsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?

    def index
        @audits = Audited::Adapters::ActiveRecord::Audit.includes(:user).reorder('id DESC').limit(20)
        @audits = @audits.paginate(:page => params[:page] || 1, :per_page => 20) if request.format.html? || request.format.js?
        respond_with(@audits) do |format|
            format.html { render :partial => 'list', :object => @audits, :as => :audits if request.xhr? }
        end
    end
end
