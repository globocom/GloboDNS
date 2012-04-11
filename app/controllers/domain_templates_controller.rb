class DomainTemplatesController < ApplicationController
    respond_to :html, :json
    responders :flash

    def index
        @domain_templates = DomainTemplate.scoped
        @domain_templates = @domain_templates.includes(:record_templates).paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
        respond_with(@domain_templates) do |format|
            format.html { render :partial => 'list', :object => @domain_templates, :as => :domain_templates if request.xhr? }
        end
    end

    def show
        @domain_template = DomainTemplate.find(params[:id])
        unless request.xhr?
            @soa_record_template = @domain_template.record_templates.where('record_type =  ?', 'SOA').first
            @record_templates    = @domain_template.record_templates.where('record_type != ?', 'SOA').paginate(:page => params[:page], :per_page => 10)
        end
        respond_with(@domain_template)
    end

    def new
        @domain_template = DomainTemplate.new
        respond_with(@domain_template)
    end

    def edit
        @domain_template = DomainTemplate.find(params[:id])
        respond_with(@domain_template)
    end

    def create
        @domain_template = DomainTemplate.new(params[:domain_template])
        @domain_template.save
        Rails.logger.info "[controller] after save"

        respond_with(@domain_template) do |format|
            format.html { render :status  => @domain_template.valid? ? :ok              : :unprocessable_entity,
                                 :partial => @domain_template.valid? ? @domain_template : 'errors' } if request.xhr?
        end
    end

    def update
        @domain_template = DomainTemplate.find(params[:id])
        @domain_template.update_attributes(params[:domain_template])
        respond_with(@domain_template) do |format|
            format.html { render :status  => @domain_template.valid? ? :ok    : :unprocessable_entity,
                                 :partial => @domain_template.valid? ? 'form' : 'errors' } if request.xhr?
        end
    end

    def destroy
        @domain_template = DomainTemplate.find(params[:id])
        @domain_template.destroy
        respond_with(@domain_template)
    end
end
