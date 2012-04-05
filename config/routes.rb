GloboDns::Application.routes.draw do
    # devise_for :users, :controllers => { :sessions => "sessions" }
    devise_for :users, :controllers => { :sessions => "sessions" }

    root :to => 'dashboard#index'

    resources :domains do
        member do
            # put :change_owner
            # get :apply_macro
            # post :apply_macro
            put :update_note
        end

        resources :records do
            member do
                put :update_soa
            end
        end
    end

    resources :zone_templates, :controller => 'templates'
    resources :record_templates

    # resources :macros do
        # resources :macro_steps
    # end

    match '/audits(/:action(/:id))' => 'audits#index', :as => :audits
    # match '/reports(/:action)' => 'reports#index', :as => :reports

    match '/export' => 'bind9#export', :as => :export
    match '/test'   => 'bind9#test',   :as => :test

    # resource :auth_token
    match '/token' => 'bind9#export', :as => :token
    match '/tooken' => 'auth_tokens#token', :as => :tooken

    resources :users do
        member do
            # put :suspend
            # put :unsuspend
            delete :purge
        end
    end

    get '/search(/:action)' => 'search#results', :as => :search
end
