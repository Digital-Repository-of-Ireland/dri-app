require 'resque/server'

NuigRnag::Application.routes.draw do
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
    root :to => "catalog#index"

    Blacklight.add_routes(self)

    mount UserGroup::Engine => "/user_groups"

    devise_for :users, :skip => [ :sessions, :registrations, :passwords], class_name: 'UserGroup::User', :controllers => { :omniauth_callbacks => "user_group/omniauth_callbacks" }

    resources :objects, :only => ['new', 'edit', 'update', 'create', 'show'] do
      resources :files, :controller => :assets, :only => ['create','show','update']
      resources :pages
    end

    resources :session, :only => ['create']

    resources :collections, :only => ['new','create','update','edit','destroy']

    resources :institutes, :only => ['show', 'new', 'create']
    resources :object_history, :only => ['show']
    resources :user_report, :only => ['index']
    resources :datastream_version, :only => ['show']

    match 'newassociation' => 'institutes#associate', :via => :post, :as => :new_association
    match 'newdepositingassociation' => 'institutes#associate_depositing', :via => :post, :as => :new_depositing_association
    match 'institutions' => 'institutes#index', :via => :get, :as => :institutions

    resources :licences

    match 'session/:id' => 'session#create', :via => :get, :as => :lang

    match 'error/404' => 'error#404', :via => :get
    match 'error/422' => 'error#422', :via => :get
    match 'error/500' => 'error#500', :via => :get

    get '/404' => 'error#error_404'
    get '/422' => 'error#error_422'
    get '/500' => 'error#error_500'

    match 'export/:id' => 'export#show', :via => :get, :as => :object_export

    match 'objects/:id/metadata' => 'metadata#show', :via => :get, :as => :object_metadata, :defaults => { :format => 'xml' }
    match 'objects/:id/metadata' => 'metadata#update', :via => :put
    match 'objects/:id/citation' => 'objects#citation', :via => :get, :as => :citation_object
    match 'objects/:object_id/files/:id/download' => 'assets#download', :via => :get, :as => :file_download
    match 'download_surrogate' => 'surrogates#download', :via => :get
    match 'maps_json' => 'maps#get', :via => :get
    match 'timeline_json' => 'timeline#get', :via => :get

    match 'objects/:id/status' => 'objects#status', :via => :put, :as => :status_update
    match 'objects/:id/status' => 'objects#status', :via => :get, :as => :status

    match 'collections/:id/publish' => 'collections#publish', :via => :put, :as => :publish
    # Added review method to collections controller
    match 'collections/:id/review' => 'collections#review', :via => :put, :as => :review

    match '/privacy' => 'static_pages#privacy', :via => :get
    match '/workspace' => 'workspace#index', :via => :get
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
  end

  match '00D9DB5F-0CC1-4AE1-B014-968AFA0371AC/pages/*id' => 'high_voltage/pages#show', :via => :get
end
