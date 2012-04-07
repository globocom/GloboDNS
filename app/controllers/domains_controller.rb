class DomainsController < ApplicationController
    respond_to :html, :json
    responders :flash

    def index
        @domains = Domain.scoped
        @domains = @domains.includes(:records).paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
        respond_with(@domains) do |format|
            format.html { render :partial => 'list', :object => @domains, :as => :domains if request.xhr? }
        end
    end

    def show
        @domain = Domain.find(params[:id])
        unless request.xhr?
            query    = params[:record].blank? ? nil : params[:record]
            @records = @domain.records.without_soa.paginate(:page => params[:page], :per_page => 10)
        end
        respond_with(@domain)
    end

    def new
        @domain = Domain.new
        respond_with(@domain)
    end

    def edit
        @domain = Domain.find(params[:id])
        respond_with(@domain)
    end

    def create
        @domain = Domain.new(params[:domain])

        if params[:domain][:zone_template_id].present? || params[:domain][:zone_template_name].present?
            @zone_template   = ZoneTemplate.where('id'   => params[:domain][:zone_template_id]).first   if params[:domain][:zone_template_id]
            @zone_template ||= ZoneTemplate.where('name' => params[:domain][:zone_template_name]).first if params[:domain][:zone_template_name]
            if @zone_template
                @domain = @zone_template.build(@domain.name)
            else
                @domain.errors.add(:zone_template, 'ZoneTemplate not found')
            end
        end

        @domain.save

        respond_with(@domain) do |format|
            format.html { render :partial => @domain, :status => :ok } if request.xhr? && @domain.valid?
            format.html { render :partial => 'new',   :status => :unprocessable_entity, :object => @domain, :as => :domain } if request.xhr? && !@domain.valid?
        end
    end

    def update
        @domain = Domain.find(params[:id])
        @domain.update_attributes(params[:domain])
        respond_with(@domain) do |format|
            format.html { render :partial => 'form', :object => @domain, :as => :domain if request.xhr? }
        end
    end

    def destroy
        @domain = Domain.find(params[:id])
        @domain.destroy
        respond_with(@domain)
    end

    def update_note
        resource.update_attribute( :notes, params[:domain][:notes] )
    end
end
