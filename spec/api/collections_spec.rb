require 'swagger_helper'

describe "Collections API" do
  path "/collections" do
    get "retrieves collections for the current user" do
      # TODO is collections really private?
      # Can access specific public collections, 
      # just not the /collections route and private/draft collections
      # without sign in
      tags 'collections'
      security [ apiKey: [], appId: [] ]
      produces 'application/json'
      # creates @example_user with authentication_token (not signed in)
      include_context 'rswag_user_with_collections', status: 'published'

      response "401", "Must be signed in or use apikey to access this route" do
        include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }

        run_test! do 
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      # TODO: fix empty output on this test by creating public collections
      # First create an organisation, then publish a collection
      # Issue with FactoryBot objects not being in solr?
      # Create real collection to update solr doc?
      context "Authenticated user with collections" do
        response "200", "All collections found" do
          include_context 'rswag_include_json_spec_output'
          let(:user_token) { @example_user.authentication_token }
          let(:user_email) { CGI.escape(@example_user.to_s) }
          run_test! 
        end
      end
    end
  end

  path "/collections/{id}" do
    # TODO break this into shared examples?
    # Common pattern in my_collections and collections
    get "retrieves a specific object, collection or subcollection" do
      tags 'collections'
      security [ apiKey: [], appId: [] ]
      produces 'application/json', 'application/xml', 'application/ttl'
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string
      include_context 'rswag_user_with_collections'

      response "401", "Must be signed in to access this route" do
        # TODO: make api response consistent
        # always return sign in error when not signed in on route that requires it
        # can't include rspec output since it's an empty string (not json)
        # include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.id }
        run_test!
      end

      response "404", "Object not found" do
        include_context 'rswag_include_json_spec_output'
        # doesn't matter whether you're signed in
        # 404 takes precendence over 401
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { "collection_that_does_not_exist" }
        run_test!
      end

      response "200", "Object found" do
        include_context 'rswag_include_json_spec_output'
        let(:user_token) { @example_user.authentication_token }
        let(:user_email) { CGI.escape(@example_user.to_s) }
        let(:id) { @collections.first.id }
        run_test!
      end
    end
  end
end
