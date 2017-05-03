require 'resque/server'

DriApp::Application.routes.draw do
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
    root :to => "catalog#index"

    mount UserGroup::Engine => "/user_groups"
    mount Riiif::Engine => '/images'

    Blacklight.add_routes(self)

    devise_for :users, :skip => [:sessions, :registrations, :passwords], class_name: 'UserGroup::User', :controllers => { :omniauth_callbacks => "user_group/omniauth_callbacks" }

    devise_scope :user do
      get '/users/sign_in', :to => 'sessions#new', :as => :new_user_session
      post '/users/sign_in', :to => 'sessions#create', :as => :user_session
      delete '/users/sign_out', :to => 'sessions#destroy', :as => :destroy_user_session
    end

    resources :objects, :only => ['new', 'edit', 'update', 'create', 'show', 'destroy'] do
      resources :files, :controller => :assets, :only => ['create','show','update','destroy']
      resources :pages
      resources :doi, :only => ['show']
    end

    resources :session, :only => ['create']

    resources :collections, :only => ['index','new','create','update','edit','destroy']
    post 'collections/:object_id/doi', to: 'doi#update', as: :collection_doi
    post 'collections/:id/organisations', to: 'institutes#set', as: :collection_organisations
    post 'collections/:id/batch', to: 'batch_ingest#create', as: :batch_ingest
    get 'collections/:id/duplicates', to: 'collections#duplicates', as: :collection_duplicates

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

    get 'activity', to: 'activity#index'

    match 'association' => 'institutes#associate', :via => :post, :as => :new_association
    match 'association' => 'institutes#disassociate', :via => :delete, :as => :disassociation
    match 'manage_users' => 'manage_users#new', :via => :get, :as => :manage_users
    match 'manage_users' => 'manage_users#create', :via => :post, :as => :new_manage_user

    resources :licences

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
    match 'objects/:id/datastreams/:stream' => 'datastream_version#show', :via => :get, :as => :datastream_version
    match 'objects/:object_id/files/:id/download' => 'assets#download', :via => :get, :as => :file_download
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
    match '/workspace/facet/:id' => 'workspace#facet', :via => :get
    match '/admin_tasks' => 'static_pages#admin_tasks', :via => :get

    get 'surrogates/:id' => 'surrogates#show', :as => :surrogates
    put 'surrogates/:id' => 'surrogates#update', :as => :surrogates_generate

    get 'tasks' => 'user_background_tasks#index', as: :user_tasks
    delete 'tasks' => 'user_background_tasks#destroy', as: :destroy_user_tasks  

    match 'collections/:id' => 'catalog#show', :via => :get

    #API paths
    match 'get_objects' => 'objects#index', :via => :post
    match 'related' => 'objects#related', :via => :get
    match 'get_assets' => 'assets#list_assets', :via => :post, :as => :list_assets

    # need to put in the 'system administrator' role here
    authenticate do
      mount Resque::Server, :at => "/resque"
    end
  end

  match 'pages/*id' => 'high_voltage/pages#show', :via => :get
end
