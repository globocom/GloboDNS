class RecordTemplatesController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?

    DEFAULT_PAGE_SIZE = 25

    def index
        @record_templates = RecordTemplate.where(:domain_template_id => params[:domain_template_id])
        @record_templates = @record_templates.without_soa.paginate(:page => params[:page], :per_page => params[:per_page] || DEFAULT_PAGE_SIZE)
        respond_with(@record_templates) do |format|
            format.html { render :partial => 'list', :object => @record_templates, :as => :record_templates if request.xhr? }
        end
    end

    def show
        @record_template = RecordTemplate.find(params[:id])
    end

    def new
        @record_template = RecordTemplate.new(:domain_template_id => params[:domain_template_id])
        respond_with(@record_template)
    end

    def edit
        @record_template = RecordTemplate.find(params[:id])
        respond_with(@record_template)
    end

    def create
        @record_template = RecordTemplate.new(params[:record_template].merge('domain_template_id' => params[:domain_template_id]))
        @record_template.save
        respond_with(@record_template) do |format|
            format.html { render :status  => @record_template.valid? ? :ok              : :unprocessable_entity,
                                 :partial => @record_template.valid? ? @record_template : 'errors' } if request.xhr?
        end
    end

    def update
        @record_template = RecordTemplate.find(params[:id])
        @record_template.update_attributes(params[:record_template])
        respond_with(@record_template) do |format|
            format.html { render :status  => @record_template.valid? ? :ok              : :unprocessable_entity,
                                 :partial => @record_template.valid? ? @record_template : 'errors' } if request.xhr?
        end
    end

    def destroy
        @record_template = RecordTemplate.find(params[:id])
        @record_template.destroy
        respond_with(@record_template) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end
end
