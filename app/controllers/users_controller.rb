class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, :only => [:token]

  before_filter do
    unless current_user.admin?
      redirect_to root_url
    end
  end

  def token
      resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      resource.ensure_authentication_token!
      respond_to do |format|
          format.json { render :status => :ok, :json => {:token => resource.auth_token}.to_json }
      end
  end

  def update
    # strip out blank params
    params[:user].delete_if { |k,v| v.blank? }
    update!
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate!
      flash[:notice] = t(:message_user_activated)
    end
    redirect_back_or_default('/')
  end

  def suspend
    resource.suspend!
    redirect_to users_path
  end

  def unsuspend
    resource.unsuspend!
    redirect_to users_path
  end

  def destroy
    resource.delete!
    redirect_to users_path
  end

  def purge
    resource.destroy
    redirect_to users_path
  end

end
