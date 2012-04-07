class RecordsController < ApplicationController
    respond_to :html, :json
    responders :flash

    def index
        @records = Record.where(:domain_id => params[:domain_id])
        @records = @records.without_soa.paginate(:page => params[:page], :per_page => 10) if request.format.html? || request.format.js?
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
        @record = Record.new(params[:record].merge('domain_id' => params[:domain_id]))
        @record.save
        respond_with(@record) do |format|
            format.html { render :partial => @record if request.xhr? }
        end
    end

    def update
        @record = Record.find(params[:id])
        @record.update_attributes(params[:record])
        respond_with(@record) do |format|
            format.html { render :partial => @record if request.xhr? }
        end
    end

    def destroy
        @record = Record.find(params[:id])
        @record.destroy
        respond_with(@record) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end

    # Non-CRUD methods
    def update_soa
        @domain = parent
        @domain.soa_record.update_attributes( params[:soa] )
    end
end
