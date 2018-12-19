require 'swagger_helper'

describe "My Collections API" do
  path "/my_collections" do
    get "retrieves objects, collections, or subcollections for the current user" do
      tags 'collections'
      security [ apiKey: [], appId: [] ]
      produces 'application/json'
      include_context 'rswag_user_with_collections'
      include_context 'doi_config_exists'
      # TODO accept ttl and xml on default route too
      # not just specific objects
      # TODO add json format for /my_collections/:id/duplicates

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9, required: false
      parameter name: :page, description: 'Page number', 
        in: :query, type: :number, default: 1, required: false
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, required: false, default: 'objects', type: :string,
        enum: ['objects', 'collections']
      parameter name: :show_subs, description: 'Show subcollections',
        in: :query, type: :boolean, default: false
      parameter name: :search_field, description: 'Solr field to search for',
        in: :query, type: :string, default: 'all_fields'
      parameter name: :sort, description: 'Solr fields to sort by',
        in: :query, type: :string, default: nil
      parameter name: :q, description: 'Search Query',
        in: :query, type: :string, default: nil
        
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false
      # # issue with facets beign empty string
      # parameter name: :f, description: 'Search facet (solr fields to filter results)',
        # in: :query, type: :string, default: nil

      # undefined method `per_page' when not set
      let(:per_page)     { 9 }
      let(:page)         { 1 }
      # although when you visit /my_collections in a web browser mode=collections
      # if you call /my_collections.json you get objects, not only collections
      let(:mode)         { 'objects' }
      let(:show_subs)    { false }
      let(:search_field) { 'all_fields' }
      let(:sort)         { nil }
      let(:q)            { nil }
      # let(:f)            { nil }
      
      response "401", "Must be signed in to access this route" do
        let(:user_token) { nil }
        let(:user_email) { nil }

        it_behaves_like 'a pretty json response'
        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a json api 401 error',
            message: "You need to sign in or sign up before continuing."
        end
      end
      response "200", "All objects found" do
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }
        context 'All objects found' do
          # it_behaves_like 'a json api with licence information'
          include_context 'rswag_include_json_spec_output', '/my_collections.json' do
            it_behaves_like 'a pretty json response'
          end
        end
        context 'All collections found' do
          let(:mode) { 'collections' }
          include_context 'rswag_include_json_spec_output', '/my_collections.json?mode=collections' do
            it_behaves_like 'a pretty json response'
          end
        end 
        context 'Show subcollections' do
          let(:mode) { 'collections' }
          let(:show_subs) { true }
          include_context 'rswag_include_json_spec_output', '/my_collections.json?mode=collections&show_subs=true' do
            # include_context 'subcollection'
            it_behaves_like 'a pretty json response'
          end
        end
        context 'Limit results' do
          let(:per_page) { 1 }
          include_context 'rswag_include_json_spec_output', '/my_collections.json?per_page=1' do
            it_behaves_like 'a pretty json response'
          end
        end
      end
    end
  end

  path "/my_collections/{id}/" do
    get "retrieves a specific object, collection or subcollection" do
      tags 'collections'
      security [ apiKey: [], appId: [] ]
      produces 'application/json', 'application/xml', 'application/ttl'

      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false

      include_context 'rswag_user_with_collections'
      include_context 'doi_config_exists'

      response "401", "Must be signed in to access this route" do
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.id }

        it_behaves_like 'a pretty json response'
        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a json api 401 error'
        end
      end

      response "404", "Object not found" do
        # doesn't matter whether you're signed in
        # 404 takes precendence over 401
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { "collection_that_does_not_exist" }

        it_behaves_like 'a json api 404 error'
        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a pretty json response'
        end
      end

      response "200", "Found" do
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }

        context 'Collection' do
          let(:id) { @collections.first.id }
          # collections should not display licence info tracker #1857
          it_behaves_like 'a pretty json response'
          it_behaves_like 'it has no json licence information'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'it has json related objects information'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.id }
          it_behaves_like 'it has json licence information'
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json doi information'
          end
        end
      end
    end
  end
end

