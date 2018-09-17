require 'swagger_helper'

describe "Collections API" do
  path "/collections" do
    get "retrieves collections for the current user" do
      # TODO is collections really private?
      # Can access specific public collections, 
      # just not the /collections route and private/draft collections
      # without sign in
      tags 'Private (Sign in required)'
      # TODO deprecate this endpoint?
      produces 'application/json'

      # undefined method `per_page' when not set
      let(:per_page) { 1 }
      let(:mode) { 'objects' }

      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        include_context 'rswag_include_json_spec_output'

        it "should require a sign in" do 
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      # TODO: fix empty output on this test
      context "Signed in user with collections" do
        include_context 'collections_with_objects'

        response "200", "All collections found" do
          include_context 'rswag_include_json_spec_output'
          run_test! do
            expect(status).to eq(200) 
          end
        end
      end
    end
  end

  path "/collections/{id}" do
    # TODO break this into shared examples?
    # Common pattern in my_collections and collections
    include_context 'collections_with_objects'

    get "retrieves a specific object, collection or subcollection" do
      tags 'Private (Sign in required)'
      produces 'application/json', 'application/xml', 'application/ttl'
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string

      # TODO: make api response consistent
      # always return sign in error when not signed in on route that requires it
      # can't include rspec output since it's an empty sting (not json)
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        let(:id) { @collections.first.id }

        it 'returns a 401 when the user is not signed in' do
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      response "404", "Object not found" do
        # doesn't matter whether you're signed in
        # 404 takes precendence over 401
        include_context 'sign_out_before_request'
        include_context 'rswag_include_json_spec_output'

        let(:id) { "collection_that_does_not_exist" }

        it 'returns a 404 when the user is not signed in' do
          expect(status).to eq(404) 
        end
      end

      response "200", "Object found" do
        include_context 'rswag_include_json_spec_output'
        let(:id) { @collections.first.id }
        run_test! do
          expect(status).to eq(200) 
        end
      end
    end
  end
end
