class AccessDeniedController < ApplicationController
  skip_before_filter :authenticate_user!
  def show
  end
end
