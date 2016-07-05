class AccessDeniedController < ApplicationController
  skip_before_filter :authenticate_user!
  def show
  	respond_to do |format|
  		format.html { render :status => :not_authorized, :file => File.join(Rails.root, 'public', '401.html'), :layout => nil }
        format.json { render :status => :forbidden,      :json => {:error => 'NOT AUTHORIZED'} }
    end
  end
end
