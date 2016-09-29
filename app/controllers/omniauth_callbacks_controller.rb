class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate_user!

  # def oauth_provider
  #   @user = User.from_omniauth(request.env["omniauth.auth"])
  #   if @user.persisted?
  #     if @user.active
  #       sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
  #       set_flash_message(:notice, :success, :kind => "oauth provider") if is_navigational_format?
  #     else
  #       session[:user_name] = @user.login
  #       flash[:alert] = t "user_deactivated"
  #       redirect_to access_denied_url
  #     end
  #   else
  #     session["devise.oauth_provider_data"] = request.env["omniauth.auth"]
  #     redirect_to new_user_session
  #   end
  # end
end