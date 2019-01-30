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

GloboDns::Application.routes.draw do
  get 'access_denied/new'
  get 'access_denied/create'
  get "access_denied" => "access_denied#show", as: :access_denied

  if GloboDns::Application.config.omniauth
    devise_for  :users, :controllers => { :omniauth_callbacks => 'omniauth_callbacks'}
    resources :views
    resources :users

    devise_scope :users do
      match 'users/sign_in' => 'access_denied#show', via: [:get, :post]
      # get 'auth/sign_in' => redirect('users/auth/oauthprovider'), :as => :new_user_session
      get 'auth/sign_out', :to => 'application#logout', :as => :destroy_user_session
    end
  else
    devise_for :users, :controllers => { :sessions => 'sessions' }
    resources :views
    resources :users

    # devise_scope :user do
    resource :user do
      get 'update_password' => 'users#update_password', :as => 'update_password'
      put 'update_password/save' => 'users#save_password_update', :as => 'save_password_update'
    end
  end

  resources :domains do
    get 'update_domain_owner', :on => :member
    resources :records, :shallow => true do
      get 'update_domain_owner', :on => :member
      get 'resolve', :on => :member
      get 'verify_owner', :on => :member
    end
  end

  resources :domain_templates do
    resources :record_templates, :shallow => true
  end

  scope 'bind9', :as => 'bind9', :controller => 'bind9' do
    get  '',       :action => 'index'
    get  'config', :action => 'configuration'
    post 'export'
    post 'schedule_export'
  end

  match '/audits(/:action(/:id))' => 'audits#index', :as => :audits, :via => :get

  root :to => 'dashboard#index'

  get 'healthcheck' => lambda { |env| [200, {"Content-Type" => "text/plain"}, ["WORKING"]] }

end
