GloboDns::Application.routes.draw do
    devise_for :users, :controllers => { :sessions => 'sessions' }

    resources :domains do
        put :update_note, :on => :member

        resources :records, :shallow => true do
            put :update_soa, :on => :member
        end
    end

    resources :users do
        delete :purge, :on => :member
    end

    resources :zone_templates, :controller => 'templates'
    resources :record_templates

    match '/search(/:action)'       => 'search#results', :as => :search, :via => :get
    match '/audits(/:action(/:id))' => 'audits#index',   :as => :audits, :via => :get
    match '/export'                 => 'bind9#export',   :as => :export, :via => :get
    match '/test'                   => 'bind9#test',     :as => :test,   :via => :get

    root :to => 'dashboard#index'
end
