class RecordsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin_or_operator?, :except => [:index, :show]
    
    DEFAULT_PAGE_SIZE = 10

    def index
        @records = Record.where(:domain_id => params[:domain_id])
        @records = @records.without_soa.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || DEFAULT_PAGE_SIZE) if request.format.html? || request.format.js?
        @records = @records.matching(params[:query]) if params[:query].present?
        respond_with(@records) do |format|
            format.html { render :partial => 'list', :object => @records, :as => :records if request.xhr? }
        end
    end

    def show
        @record = Record.find(params[:id])
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
        @record = params[:record][:type].constantize.new(params[:record])
        @record.domain_id = params[:domain_id]
        @record.save
        respond_with(@record) do |format|
            format.html { render :status  => @record.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @record.valid? ? @record : 'errors' } if request.xhr?
        end
    end

    def update
        @record = Record.find(params[:id])
        @record.update_attributes(params[:record])
        respond_with(@record) do |format|
            format.html { render :status  => @record.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @record.valid? ? @record : 'errors' } if request.xhr?
        end
    end

    def destroy
        @record = Record.find(params[:id])
        @record.destroy
        respond_with(@record) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end
end
