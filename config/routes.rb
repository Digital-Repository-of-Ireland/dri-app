require 'resque/server'

NuigRnag::Application.routes.draw do
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
  root :to => "catalog#index"

  Blacklight.add_routes(self)
  #HydraHead.add_routes(self)

  mount UserGroup::Engine => "/user_groups"

  devise_for :users, :skip => [ :sessions, :registrations, :passwords], class_name: 'UserGroup::User', :controllers => { :omniauth_callbacks => "user_group/omniauth_callbacks" }

  resources :objects, :only => ['edit', 'update', 'create', 'show'] do
  resources :files, :controller => :assets, :only => ['create','show','update']
  resources :pages
  end

  resources :session, :only => ['create']

  resources :collections, :only => ['new','create','update','edit','destroy']

  resources :ingest, :only => ['new', 'create']

  resources :institutes, :only => ['show', 'new', 'create']
  match 'newassociation' => 'institutes#associate', :via => :post, :as => :new_association

  resources :licences

  match 'session/:id' => 'session#create', :via => :get, :as => :lang

  match 'error/404' => 'error#404', :via => :get
  match 'error/422' => 'error#422', :via => :get
  match 'error/500' => 'error#500', :via => :get

  match '/404' => 'error#error_404'
  match '/422' => 'error#error_422'
  match '/500' => 'error#error_500'

  match 'export/:id' => 'export#show', :via => :get, :as => :object_export

  match 'objects/:id/metadata' => 'metadata#show', :via => :get, :as => :object_metadata
  match 'objects/:id/metadata' => 'metadata#update', :via => :put
  match 'objects/:id/citation' => 'objects#citation', :via => :get, :as => :citation_object
  match 'objects/:object_id/files/:id/download' => 'assets#download', :via => :get, :as => :file_download

  match 'objects/:id/status' => 'objects#status', :via => :put, :as => :status_update
  match 'objects/:id/status' => 'objects#status', :via => :get, :as => :status

  match 'collections/:id/publish' => 'collections#publish', :via => :put, :as => :publish

  match '/privacy' => 'static_pages#privacy', :via => :get
  match '/workspace' => 'static_pages#workspace', :via => :get
  match '/admin_tasks' => 'static_pages#admin_tasks', :via => :get
  match 'user_groups/users/sign_in' => 'devise/sessions_controller#new', :via => :get, :as => :new_user_session

  match 'surrogates/:id' => 'surrogates#update', :via => :put, :as => :surrogates_generate
  match 'surrogates/:id' => 'surrogates#show', :via => :get, :as => :surrogates

  match 'collections/:id' => 'catalog#show', :via => :get
  match 'collections/ingest' => 'collections#ingest', :via => :post

  #API paths
  match 'get_objects' => 'objects#index', :via => :post
  match 'related' => 'objects#related', :via => :get
  match 'get_assets' => 'assets#list_assets', :via => :post, :as => :list_assets

  # need to put in the 'system administrator' role here
  authenticate do
    mount Resque::Server, :at => "/resque"
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  end

  match '00D9DB5F-0CC1-4AE1-B014-968AFA0371AC/pages/*id' => 'high_voltage/pages#show', :via => :get

end
