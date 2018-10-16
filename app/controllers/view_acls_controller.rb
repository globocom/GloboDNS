class ViewAclsController < ApplicationController

  def new
    @view_acl = ViewAcl.new
    respond_with(@view_acl)
  end

  def create
    @view_acl = ViewAcl.new(params[:view_acl])
    redirect_to view_path(@view_acl.view_id) if @view_acl.save
  end

  def destroy
    @view_acl = ViewAcl.find(params[:id])
    @view_acl.destroy
    redirect_to view_path(@view_acl.view_id)
  end
end
