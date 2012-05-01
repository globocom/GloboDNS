class ViewsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?

    def index
        @views = View.scoped
        @views = @views.paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
        respond_with(@views) do |format|
            format.html { render :partial => 'list', :object => @views, :as => :views if request.xhr? }
        end
    end

    def show
        @view = View.find(params[:id])
        respond_with(@view)
    end

    def new
        @view = View.new
        respond_with(@view)
    end

    def edit
        @view = View.find(params[:id])
        respond_with(@view)
    end

    def create
        @view = View.new(params[:view])
        @view.save

        respond_with(@view) do |format|
            format.html { render :status  => @view.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @view.valid? ? @view : 'errors' } if request.xhr?
        end
    end

    def update
        if params[:view] && params[:view][:password].blank? && params[:view][:password_confirmation].blank?
            params[:view].delete(:password)
            params[:view].delete(:password_confirmation)
        end
        @view = View.find(params[:id])
        @view.update_attributes(params[:view])

        respond_with(@view) do |format|
            format.html { render :status  => @view.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @view.valid? ? @view : 'errors' } if request.xhr?
        end
    end

    def destroy
        @view = View.find(params[:id])
        @view.destroy
        respond_with(@view) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end
end
