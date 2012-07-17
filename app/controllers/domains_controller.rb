class DomainsController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin_or_operator?, :except => [:index, :show]

    def index
        session[:show_reverse_domains] = (params[:reverse] == 'true') if params.has_key?(:reverse)
        @domains = session[:show_reverse_domains] ? Domain.scoped : Domain.nonreverse
        @domains = @domains.includes(:records).paginate(:page => params[:page], :per_page => 5) if navigation_format?
        @domains = @domains.matching(params[:query]) if params[:query].present?
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
        if params[:domain][:domain_template_id].present? || params[:domain][:domain_template_name].present?
            @domain_template   = DomainTemplate.where('id'   => params[:domain][:domain_template_id]).first   if params[:domain][:domain_template_id]
            @domain_template ||= DomainTemplate.where('name' => params[:domain][:domain_template_name]).first if params[:domain][:domain_template_name]
            if @domain_template
                @domain = @domain_template.build(params[:domain][:name])
            else
                @domain.errors.add(:domain_template, 'Domain Template not found')
            end
        else
            @domain = Domain.new(params[:domain].except(:domain_template_id, :domain_template_name))
        end

        @domain.save
        flash[:warning] = "#{@domain.warnings.full_messages * '; '}" if @domain.has_warnings? && request.navigational_format?

        respond_with(@domain) do |format|
            format.html { render :status  => @domain.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @domain.valid? ? @domain : 'errors' } if request.xhr?
        end
    end

    def update
        @domain = Domain.find(params[:id])
        @domain.update_attributes(params[:domain])
        flash[:warning] = "#{@domain.warnings.full_messages * '; '}" if @domain.has_warnings? && navigation_format?

        respond_with(@domain) do |format|
            format.html { render :status  => @domain.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @domain.valid? ? 'form'  : 'errors',
                                 :object  => @domain, :as => :domain } if request.xhr?
        end
    end

    def destroy
        @domain = Domain.find(params[:id])
        @domain.destroy
        respond_with(@domain)
    end
end
