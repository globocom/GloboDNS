class AclsController < ApplicationController
  respond_to :html, :json
  responders :flash

  before_filter :admin?


  def countries
    render json: CS.countries.invert.to_json
  end

  def regions
    render json: CS.states(params[:country]).invert.to_json
  end

  def cities
    render json: CS.cities(params[:region], params[:country]).to_json
  end

  def index
    @acls = Acl.all
    @acls = @acls.paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
    @acls = @acls.where(name: params[:query]) if params[:query]
    @countries = CS.countries.invert
    respond_with(@acls) do |format|
      format.html { render :partial => 'list', :object => @acls, :as => :acls if request.xhr? }
    end
  end

  def show
    @acl = Acl.find(params[:id])
    @acls = @acl.available_acls.collect{|acl| [acl.name, acl.id]}
    respond_with(@acl)
  end

  def new
    @acl = Acl.new
    respond_with(@acl)
  end

  def edit
    @acl = Acl.find(params[:id])
    respond_with(@acl)
  end

  def create
    @acl = Acl.new(params[:acl])
    @acl.save

    respond_with(@acl) do |format|
      format.html { render :status  => @acl.valid? ? :ok     : :unprocessable_entity,
                    :partial => @acl.valid? ? @acl : 'errors' } if request.xhr?
    end
  end

  def update
    @acl = Acl.find(params[:id])
    @acl.update_attributes(params[:acl])

    respond_with(@acl) do |format|
      format.html { render :status  => @acl.valid? ? :ok     : :unprocessable_entity,
                    :partial => @acl.valid? ? 'form' : 'errors' } if request.xhr?
    end
  end

  def destroy
    @acl = Acl.find(params[:id])

    if @acl.can_be_deleted?
      @acl.destroy
      respond_with(@acl)
    else
      @acl.errors.add(:id, "View is associated to a domain/domain template")
      respond_with(@acl)
    end
  end
end
