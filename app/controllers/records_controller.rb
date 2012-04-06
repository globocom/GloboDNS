class RecordsController < InheritedResources::Base
  belongs_to :domain, :shallow => true
  respond_to :xml, :json, :js

  public

  # Non-CRUD methods
  def update_soa
    @domain = parent
    @domain.soa_record.update_attributes( params[:soa] )
  end
end
