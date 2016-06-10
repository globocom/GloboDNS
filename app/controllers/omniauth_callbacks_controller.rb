class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate_user!

  def backstage
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      if @user.active
        sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
        set_flash_message(:notice, :success, :kind => "Backstage") if is_navigational_format?
      else
        session[:user_name] = @user.name
        flash[:alert] = t "user_deactivated"
        redirect_to access_denied_url
      end
    else
      session["devise.backstage_data"] = request.env["omniauth.auth"]
      redirect_to new_user_session
    end
  end
end