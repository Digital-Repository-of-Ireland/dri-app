require 'swagger_helper'

describe "Collections API" do
  path "/collections" do
    get "retrieves collections for the current user" do
      # TODO is collections really private?
      # Can access specific public collections,
      # just not the /collections route and private/draft collections
      # without sign in

      # creates @example_user with authentication_token (not signed in)
      include_context 'rswag_user_with_collections', status: 'published'
      include_context 'doi_config_exists'

      produces 'application/json'
      pretty_json_param
      tags 'collections'
      security [ apiKey: [], appId: [] ]

      response "401", "Must be signed in or use apikey to access this route" do
        include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }

        it_behaves_like 'a json api 401 error',
          message: "You need to sign in or sign up before continuing."
        it_behaves_like 'a pretty json response'
      end

      context "Authenticated user with collections" do
        response "200", "All collections found" do
          include_context 'rswag_include_json_spec_output'
          let(:user_token) { @example_user.authentication_token }
          let(:user_email) { CGI.escape(@example_user.to_s) }
          it_behaves_like 'a pretty json response'
        end
      end
    end
  end

  path "/collections/{id}" do
    # TODO break this into shared examples?
    # Common pattern in my_collections and collections
    get "retrieves a specific object, collection or subcollection" do
      include_context 'rswag_user_with_collections'
      include_context 'doi_config_exists'

      produces 'application/json', 'application/xml', 'application/ttl'
      parameter name: :id, description: 'Object ID',
                in: :path, :type => :string
      pretty_json_param
      tags 'collections'
      security [ apiKey: [], appId: [] ]

      response "401", "Must be signed in to access this route" do
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.alternate_id }

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

        include_context 'rswag_include_json_spec_output' do
          it_behaves_like 'a json api 404 error'
          it_behaves_like 'a pretty json response'
        end
      end

      response "200", "Found" do
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }
        context 'Collection' do
          let(:id) { @collections.first.alternate_id }
          it_behaves_like 'it has no json licence information'
          it_behaves_like 'it has json related objects information'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'a pretty json response'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.alternate_id }
          it_behaves_like 'it has json licence information'
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json doi information'
          end
        end
      end
    end
  end
end
