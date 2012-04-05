class SessionsController < Devise::SessionsController
    skip_before_filter :login_required, :except => [ :destroy ]

    def create
        resource = warden.authenticate!(auth_options)
        set_flash_message(:notice, :signed_in) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_in_path_for(resource) do |format|
            format.json { render :status => :ok, :json => resource.auth_json }
        end
    end
end
