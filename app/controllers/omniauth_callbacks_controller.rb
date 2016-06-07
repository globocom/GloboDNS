# class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

#   def all
#     user = User.from_omniauth(env['omniauth.auth'], current_user)
#     if user.persisted?
#       sign_in user
#       flash[:notice] = t('devise.omniauth_callbacks.success', :kind => User::SOCIALS[params[:action].to_sym])
#       if user.sign_in_count == 1
#         redirect_to first_login_path
#       else
#         redirect_to cabinet_path
#       end
#     else
#       session['devise.user_attributes'] = user.attributes
#       redirect_to new_user_registration_url
#     end
#   end

#   User::SOCIALS.each do |k, _|
#     alias_method k, :all
#   end
# end

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
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