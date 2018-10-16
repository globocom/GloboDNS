class AclRelationshipsController < ApplicationController
  def new
    @child = AclRelationship.new
    respond_with(@child)
  end

  def create
    @child = AclRelationship.new(params[:acl_relationship])
    redirect_to acl_path(@child.acl_id) if @child.save
  end

  def destroy
    @child = AclRelationship.find(params[:id])
    @child.destroy
    redirect_to acl_path(@child.acl_id)
  end
end
