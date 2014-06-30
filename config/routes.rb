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
    devise_for :users, :controllers => { :sessions => 'sessions' }

    resources :domains do
        resources :records, :shallow => true do
            get 'resolve', :on => :member
        end
    end

    resources :domain_templates do
        resources :record_templates, :shallow => true
    end

    resources :views

    resources :users

    resource :user do
      get 'update_password' => 'users#update_password', :as => 'update_password'
      put 'update_password/save' => 'users#save_password_update', :as => 'save_password_update'
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
