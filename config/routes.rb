require 'resque/server'

NuigRnag::Application.routes.draw do
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
    root :to => "catalog#index"

    #Blacklight.add_routes(self)

    mount UserGroup::Engine => "/user_groups"

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
  
    put 'collections/:id/licences', to: 'collections#set_licence', as: :collection_licence
    put 'objects/:id/licences', to: 'objects#set_licence', as: :object_licence

    get 'objects/:id/access', to: 'access_controls#edit', as: :access_controls
    put 'objects/:id/access', to: 'access_controls#update'
  
    resources :organisations, controller: :institutes
    get 'organisations/:id/logo', to: 'institutes#logo', as: :logo

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

    put 'surrogates/:id' => 'surrogates#update', :as => :surrogates_generate
    get 'surrogates/:id' => 'surrogates#show', :as => :surrogates
    get 'surrogates/:id/download' => 'surrogates#download', :as => :surrogate_download

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
