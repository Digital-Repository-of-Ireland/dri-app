require 'resque/server'

Rails.application.routes.draw do
  mount Qa::Engine => '/qa'

  mount Rswag::Ui::Engine => '/api-docs', as: 'rswag'
  mount Rswag::Api::Engine => '/api-docs'
  scope ENV["RAILS_RELATIVE_URL_ROOT"] || "/" do
    root :to => redirect('/catalog?mode=collections&search_field=all_fields')

    mount UserGroup::Engine => "/user_groups"
    mount Riiif::Engine => '/images', as: 'riiif'
    mount DriBatchIngest::Engine => '/ingest'

    mount Blacklight::Engine => '/'
    mount BlacklightAdvancedSearch::Engine => '/'

    concern :searchable, Blacklight::Routes::Searchable.new
    concern :exportable, Blacklight::Routes::Exportable.new

    delete "saved_searches/clear",       :to => "saved_searches#clear",   :as => "clear_saved_searches"
    get "saved_searches",       :to => "saved_searches#index",   :as => "saved_searches"
    put "saved_searches/save",    :to => "saved_searches#save",    :as => "save_search"
    delete "saved_searches/forget/:id",  :to => "saved_searches#forget",  :as => "forget_search"
    post "saved_searches/forget/:id",  :to => "saved_searches#forget"

    resource :catalog, only: [:index], controller: 'catalog' do
      concerns :searchable
    end
    get 'catalog/:id', to: 'catalog#show', as: :catalog

    resource :my_collections, only: [:index], controller: 'my_collections' do
      concerns :searchable
    end

    resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
      concerns :exportable
    end

    resources :bookmarks do
      concerns :exportable

      collection do
        delete 'clear'
      end
    end

    concern :oai_provider, BlacklightOaiProvider::Routes.new
    scope controller: "oai_pmh", as: "oai_pmh" do
      concerns :oai_provider
    end

    devise_for :users, :skip => [:sessions, :registrations, :passwords], class_name: 'UserGroup::User', :controllers => { :omniauth_callbacks => "user_group/omniauth_callbacks" }

    get 'objects/:object_id/files/:id', to: 'surrogates#show', constraints: { query_string: /surrogate=([^&]*)/ }
    resources :objects, :only => ['new', 'edit', 'update', 'create', 'show', 'destroy'] do
      resources :files, controller: :assets, :only => ['new','index', 'create','show','update','destroy']
      resources :pages
      resources :doi, :only => ['show']
    end

    resources :session, :only => ['create']

    resources :collections, :only => ['index','new','create','update','edit','destroy']

    post 'collections/:object_id/doi', to: 'doi#update', as: :collection_doi
    post 'collections/:id/organisations', to: 'institutes#set', as: :collection_organisations

    get 'collections/:collection_id/config', to: 'collection_configs#show', as: :collection_config
    put 'collections/:collection_id/config', to: 'collection_configs#update', as: :update_collection_config

    put 'collections/:id/fixity', to: 'fixity#update', as: :fixity_check
    put 'objects/:id/fixity', to: 'fixity#update', as: :object_fixity_check

    get 'collections/:id/readers', to: 'readers#index', as: :collection_manage_requests
    post 'collections/:id/readers', to: 'readers#create', as: :collection_request_read
    get 'collections/:id/readers/:user_id', to: 'readers#show', as: :collection_view_read_request
    put 'collections/:id/readers/:user_id', to: 'readers#update', as: :collection_approve_read_request
    delete 'collections/:id/readers/:user_id', to: 'readers#destroy', as: :collection_remove_read

    put 'collections/:id/licences', to: 'collections#set_licence', as: :collection_licence
    put 'objects/:id/licences', to: 'objects#set_licence', as: :object_licence

    put 'collections/:id/copyrights', to: 'collections#set_copyright', as: :collection_copyright
    put 'objects/:id/copyrights', to: 'objects#set_copyright', as: :object_copyright

    post 'collections/:id/lock', to: 'collections#lock', as: :collection_lock
    delete 'collections/:id/lock', to: 'collections#lock', as: :collection_unlock

    get 'collections/:id/exports/new', to: 'exports#new', as: :new_export
    post 'collections/:id/exports', to: 'exports#create', as: :exports
    get 'collections/:id/exports/:export_key', to: 'exports#show', as: :export

    get 'workspace/downloads', to: 'exports#index', as: :downloads

    get 'objects/:id/access', to: 'access_controls#edit', as: :access_controls
    put 'objects/:id/access', to: 'access_controls#update'

    post 'objects/:id/tp_data', to: 'tp_data#create', as: :tp_data
    get 'tp_data/:id' => 'tp_data#edit', as: :review_tp_data

    get 'iiif/:id/manifest', to: 'iiif#manifest', as: :iiif_manifest
    get 'iiif/collection/:id', to: 'iiif#manifest', as: :iiif_collection_manifest
    get 'iiif/:id/sequence', to: 'iiif#sequence', as: :iiif_collection_sequence
    get 'iiif/:id', to: 'iiif#show'

    resources :organisations, controller: :institutes
    get 'organisations/:id/logo', to: 'institutes#logo', as: :logo

    get 'reports', to: 'reports#index'

    resources :analytics, only: ['index', 'show']

    post 'association' => 'institutes#associate', as: :new_association
    delete 'association' => 'institutes#disassociate', as: :disassociation
    get 'manage_users' => 'manage_users#new', as: :manage_users
    post 'manage_users' => 'manage_users#create', as: :new_manage_user
    get 'manage_users/:user_id', to: 'manage_users#show'
    delete 'manage_users/:user_id', to: 'manage_users#destroy'

    resources :licences 
    resources :copyrights

    get 'resource/:object', to: 'resources#show', defaults: { format: 'ttl' }

    get 'session/:id' => 'session#create', as: :lang

    get 'error/404' => 'error#404'
    get 'error/422' => 'error#422'
    get 'error/500' => 'error#500'
    

    get '/404' => 'error#error_404'
    get '/422' => 'error#error_422'
    get '/500' => 'error#error_500'
   
    get 'objects/:id/metadata' => 'metadata#show', as: :object_metadata, defaults: { format: 'xml' }
    put 'objects/:id/metadata' => 'metadata#update'
    get 'objects/:id/citation' => 'objects#citation', as: :citation_object
    get 'objects/:id/history' => 'object_history#show', as: :object_history
    get 'objects/:id/versions/:version_id' => 'object_history#download_version', as: :object_version 

    get 'objects/:object_id/files/:id/download', to: 'surrogates#download', constraints: { query_string: /type=surrogate/ }
    get 'objects/:object_id/files/:id/download', to: 'assets#download', as: :file_download

    get 'objects/:id/retrieve/:archive' => 'objects#retrieve', as: :retrieve_archive
    put 'objects/:id/status' => 'objects#status', as: :status_update
    get 'objects/:id/status' => 'objects#status', as: :status

    get 'maps/:id' => 'maps#show', as: :maps
    #match 'timeline_json' => 'timeline#get', :via => :get

    put 'collections/:id/publish' => 'collections#publish', as: :publish
    # Added review method to collections controller
    put 'collections/:id/review' => 'collections#review', as: :review
    put 'collections/:id/cover' => 'collections#add_cover_image', as: :add_cover_image
    get 'collections/:id/cover' => 'collections#cover', as: :cover_image

    get '/privacy' => 'static_pages#privacy'
    
    get '/workspace' => 'workspace#index'
    get '/workspace/collections' => 'workspace#collections', as: :workspace_collections
    get '/workspace/readers' => 'workspace#readers', as: :manage_access_requests

    get '/admin_tasks' => 'static_pages#admin_tasks'

    get '/my_collections' => 'my_collections#index', as: :my_collections_index
    get '/my_collections/facet/:id' => 'my_collections#facet'
    get '/my_collections/:id' => 'my_collections#show', as: :my_collections
    get 'my_collections/:id/duplicates', to: 'my_collections#duplicates', as: :collection_duplicates
    get 'my_collections/:id/access' => 'access_controls#show', as: :access_controls_review

    get 'surrogates/:id' => 'surrogates#index', as: :surrogates
    put 'surrogates/:id' => 'surrogates#update', as: :surrogates_generate

    get 'collections/:id' => 'catalog#show'
    get 'objects/:id' => 'objects#show'

    get 'embed3d/:object_id/files/:id/' => 'embed3d#show',  as: :embed3d_display

    get 'aggregations/:id' => 'aggregations#edit', as: :edit_edm_settings
    put 'aggregations/:id' => 'aggregations#update', as: :save_edm_settings

    get 'linkset/:id/json' => 'linksets#json', as: :linkset_json
    get 'linkset/:id/lset' => 'linksets#lset', as: :linkset_lset

    #API paths
    post 'get_objects' => 'api#objects'
    get 'related' => 'api#related'
    post 'get_assets' => 'api#assets', as: :list_assets
    match '*get_assets', via: :options, to:  lambda {|_| [204, {'Access-Control-Allow-Headers' => "Origin, Content-Type, Accept, Authorization, Token", 'Access-Control-Allow-Origin' => "*", 'Content-Type' => 'text/plain'}, []]}
    post 'enrichments' => 'api#enrichments'

    resque_web_constraint = lambda do |request|
      current_user = request.env['warden'].user
      current_user.present? && current_user.respond_to?(:is_admin?) && current_user.is_admin?
    end
    constraints resque_web_constraint do
      mount Resque::Server, at: "/resque"
    end
  end

  get 'pages/*id' => 'high_voltage/pages#show'

   namespace 'api' do 
      get 'oembed' , to: 'oembed#show' , constraints: ->(request){ request.query_parameters["url"].present? } , defaults: { format: 'json' }
   end
end
