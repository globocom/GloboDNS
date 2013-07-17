class UsersController < ApplicationController
    respond_to :html, :json
    responders :flash

    before_filter :admin?

    def index
        @users = User.scoped
        @users = @users.paginate(:page => params[:page], :per_page => 5) if request.format.html? || request.format.js?
        respond_with(@users) do |format|
            format.html { render :partial => 'list', :object => @users, :as => :users if request.xhr? }
        end
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

    def update_password
      @user = User.find(current_user.id)
      respond_to do |format|
        format.html
      end
    end
    
    def save_password_update
      @user = User.find(current_user.id)
      logger.info "Changing password for user #{@user.email}"
      
      if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
        @user.save
        flash[:notice] = t(:successful_password_change, :user => @user.email)
        redirect_to(root_path)
      else
        render :action => :update_password
      end
      
      # respond_to do |format|
      #   format.html
      # end
    end
    
    def create
        @user = User.new(params[:user])
        @user.save

        respond_with(@user) do |format|
            format.html { render :status  => @user.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @user.valid? ? @user : 'errors' } if request.xhr?
        end
    end

    def update
        if params[:user] && params[:user][:password].blank? && params[:user][:password_confirmation].blank?
            params[:user].delete(:password)
            params[:user].delete(:password_confirmation)
        end
        @user = User.find(params[:id])
        @user.update_attributes(params[:user])

        respond_with(@user) do |format|
            format.html { render :status  => @user.valid? ? :ok     : :unprocessable_entity,
                                 :partial => @user.valid? ? @user : 'errors' } if request.xhr?
        end
    end

    def destroy
        @user = User.find(params[:id])
        @user.destroy
        respond_with(@user) do |format|
            format.html { head :no_content if request.xhr? }
        end
    end

end
