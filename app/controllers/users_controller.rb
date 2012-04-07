class UsersController < ApplicationController
    respond_to :html
    responders :flash

    before_filter do
        unless current_user.admin?
            redirect_to root_url
        end
    end

    def index
        @users = User.scoped
        # @users = @users.paginate(:page => params[:page], :per_page => 20) unless request.xhr?
        respond_with(@users)
    end

    def show
        @user = User.find(params[:id])
        respond_with(@user)
    end

    def new
        @user = User.new
        respond_with(@user)
    end

    def edit
        @user = User.find(params[:id])
        respond_with(@user)
    end

    def create
        @user = User.new(params[:user])
        @user.save
        respond_with(@user)
    end

    def update
        @user = User.find(params[:id])
        @user.update_attributes(params[:user])
        respond_with(@user)
    end

    def destroy
        @user = User.find(params[:id])
        @user.destroy
        respond_with(@user)
    end
end
