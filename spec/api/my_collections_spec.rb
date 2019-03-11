require 'swagger_helper'

describe "My Collections API" do
  path "/my_collections" do
    get "retrieves published (public) and draft (private) objects, collections, or subcollections" do
      include_context 'rswag_user_with_collections'
      include_context 'doi_config_exists'
      
      produces 'application/json'
      security [ apiKey: [], appId: [] ]
      tags 'collections'
      # TODO accept ttl and xml on default route too
      # not just specific objects
      # TODO add json format for /my_collections/:id/duplicates

      # also accepts q, but that runs the same search as the catalog endpoint
      parameter name: :q_ws, description: 'Search Query',
                in: :query, type: :string, default: nil
      # helper methods that call rswag parameter methods
      search_controller_params(MyCollectionsController.blacklight_config)
      default_search_params
      default_page_params
      pretty_json_param

      let(:q_ws) { nil }
        
      # # issue with facets being empty string
      # parameter name: :f, description: 'Search facet (solr fields to filter results)',
        # in: :query, type: :string, default: nil
      
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
        context 'Search fields' do
          # no output for these specs, just ensure no duplicates are found
          it_behaves_like 'it accepts search_field params', MyCollectionsController, :q_ws
        end
      end
    end
  end

  path "/my_collections/{id}/" do
    get "retrieves a specific object, collection or subcollection" do
      include_context 'rswag_user_with_collections'
      include_context 'doi_config_exists'

      produces 'application/json', 'application/xml', 'application/ttl'
      tags 'collections'
      security [ apiKey: [], appId: [] ]

      parameter name: :id, description: 'Object ID',
                in: :path, type: :string
      pretty_json_param

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

