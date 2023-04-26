# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class UsersController < ApplicationController
  respond_to :html, :json
  responders :flash

  before_filter :admin?, :except => [:update_password, :save_password_update]

  def index
    @users = User.all
    if params[:user_query]
      @users = User.where("login like :login or email like :email", login: "%#{params[:user_query]}%", email: "%#{params[:user_query]}%")
    end
    @users = @users.paginate(:page => params[:page], :per_page => 25) if request.format.html? || request.format.js?
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
      redirect_to(root_path, :notice => t(:successful_password_change, :user => @user.email))
    else
      render :action => :update_password
    end
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
