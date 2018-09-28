require 'resque/server'

DriApp::Application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
    root :to => redirect('/catalog?mode=collections&search_field=all_fields')

    mount UserGroup::Engine => "/user_groups"
    mount Riiif::Engine => '/images'
    mount DriBatchIngest::Engine => '/ingest'

    Blacklight.add_routes(self)
    
    concern :oai_provider, BlacklightOaiProvider::Routes.new
    scope controller: "oai_pmh", as: "oai_pmh" do
      concerns :oai_provider
    end
   
    devise_for :users, :skip => [:sessions, :registrations, :passwords], class_name: 'UserGroup::User', :controllers => { :omniauth_callbacks => "user_group/omniauth_callbacks" }

    devise_scope :user do
      get '/users/sign_in', :to => 'sessions#new', :as => :new_user_session
      post '/users/sign_in', :to => 'sessions#create', :as => :user_session
      delete '/users/sign_out', :to => 'sessions#destroy', :as => :destroy_user_session
    end

    get 'objects/:object_id/files/:id', to: 'surrogates#show', constraints: { query_string: /surrogate=([^&]*)/ }
    resources :objects, :only => ['new', 'edit', 'update', 'create', 'show', 'destroy'] do
      resources :files, :controller => :assets, :only => ['create','show','update','destroy']
      resources :pages
      resources :doi, :only => ['show']
    end

    resources :session, :only => ['create']

    resources :collections, :only => ['index','new','create','update','edit','destroy']
    post 'collections/:object_id/doi', to: 'doi#update', as: :collection_doi
    post 'collections/:id/organisations', to: 'institutes#set', as: :collection_organisations
    
    put 'collections/:id/fixity', to: 'fixity#update', as: :fixity_check
    put 'objects/:id/fixity', to: 'fixity#update', as: :object_fixity_check

    get 'collections/:id/readers', to: 'readers#index', as: :collection_manage_requests
    post 'collections/:id/readers', to: 'readers#create', as: :collection_request_read
    get 'collections/:id/readers/:user_id', to: 'readers#show', as: :collection_view_read_request
    put 'collections/:id/readers/:user_id', to: 'readers#update', as: :collection_approve_read_request
    delete 'collections/:id/readers/:user_id', to: 'readers#destroy', as: :collection_remove_read

    put 'collections/:id/licences', to: 'collections#set_licence', as: :collection_licence
    put 'objects/:id/licences', to: 'objects#set_licence', as: :object_licence

    post 'collections/:id/lock', to: 'collections#lock', as: :collection_lock
    delete 'collections/:id/lock', to: 'collections#lock', as: :collection_unlock

    get 'collections/:id/exports/new', to: 'exports#new', as: :new_export
    post 'collections/:id/exports', to: 'exports#create', as: :exports
    get 'collections/:id/exports/:export_key' => 'exports#show', :as => :export
 
    get 'objects/:id/access', to: 'access_controls#edit', as: :access_controls
    put 'objects/:id/access', to: 'access_controls#update'

    get 'iiif/:id/manifest', to: 'iiif#manifest', as: :iiif_manifest
    get 'iiif/collection/:id', to: 'iiif#manifest', as: :iiif_collection_manifest
    get 'iiif/:id', to: 'iiif#show'
 
    resources :organisations, controller: :institutes
    get 'organisations/:id/logo', to: 'institutes#logo', as: :logo

    get 'reports', to: 'reports#index'

    resources :analytics, :only => ['index', 'show']

    match 'association' => 'institutes#associate', :via => :post, :as => :new_association
    match 'association' => 'institutes#disassociate', :via => :delete, :as => :disassociation
    match 'manage_users' => 'manage_users#new', :via => :get, :as => :manage_users
    match 'manage_users' => 'manage_users#create', :via => :post, :as => :new_manage_user

    resources :licences

    get 'resource/:object', to: 'resources#show', defaults: { format: 'ttl' }

    match 'session/:id' => 'session#create', :via => :get, :as => :lang

    match 'error/404' => 'error#404', :via => :get
    match 'error/422' => 'error#422', :via => :get
    match 'error/500' => 'error#500', :via => :get

    get '/404' => 'error#error_404'
    get '/422' => 'error#error_422'
    get '/500' => 'error#error_500'

    match 'objects/:id/metadata' => 'metadata#show', :via => :get, :as => :object_metadata, :defaults => { :format => 'xml' }
    match 'objects/:id/metadata' => 'metadata#update', :via => :put
    match 'objects/:id/citation' => 'objects#citation', :via => :get, :as => :citation_object
    match 'objects/:id/history' => 'object_history#show', :via => :get, :as => :object_history

    get 'objects/:object_id/files/:id/download', to: 'surrogates#download', constraints: { query_string: /type=surrogate/ }
    get 'objects/:object_id/files/:id/download', to: 'assets#download', as: :file_download

    match 'objects/:id/retrieve/:archive' => 'objects#retrieve', :via => :get, :as => :retrieve_archive

    match 'objects/:id/status' => 'objects#status', :via => :put, :as => :status_update
    match 'objects/:id/status' => 'objects#status', :via => :get, :as => :status

    match 'maps/:id' => 'maps#show', :via => :get, :as => :maps
    #match 'timeline_json' => 'timeline#get', :via => :get

    match 'collections/:id/publish' => 'collections#publish', :via => :put, :as => :publish
    # Added review method to collections controller
    match 'collections/:id/review' => 'collections#review', :via => :put, :as => :review
    match 'collections/:id/cover' => 'collections#add_cover_image', :via => :put, :as => :add_cover_image
    get 'collections/:id/cover' => 'collections#cover', as: :cover_image

    match '/privacy' => 'static_pages#privacy', :via => :get
    match '/workspace' => 'workspace#index', :via => :get
    match '/admin_tasks' => 'static_pages#admin_tasks', :via => :get

    match '/my_collections' => 'my_collections#index', :via => :get, as: :my_collections_index
    match '/my_collections/facet/:id' => 'my_collections#facet', :via => :get
    match '/my_collections/:id' => 'my_collections#show', :via => :get, as: :my_collections
    get 'my_collections/:id/duplicates', to: 'my_collections#duplicates', as: :collection_duplicates

    get 'surrogates/:id' => 'surrogates#index', as: :surrogates
    put 'surrogates/:id' => 'surrogates#update', as: :surrogates_generate

    get 'tasks' => 'user_background_tasks#index', as: :user_tasks
    delete 'tasks' => 'user_background_tasks#destroy', as: :destroy_user_tasks  

    match 'collections/:id' => 'catalog#show', :via => :get

    #API paths
    match 'get_objects' => 'objects#index', via: :post
    match 'related' => 'objects#related', via: :get
    match 'get_assets' => 'assets#list_assets', via: :post, as: :list_assets
    match '*get_assets', via: [:options], to:  lambda {|_| [204, {'Access-Control-Allow-Headers' => "Origin, Content-Type, Accept, Authorization, Token", 'Access-Control-Allow-Origin' => "*", 'Content-Type' => 'text/plain'}, []]}

    # need to put in the 'system administrator' role here
    authenticate do
      mount Resque::Server, :at => "/resque"
    end
  end

  match 'pages/*id' => 'high_voltage/pages#show', :via => :get
end
