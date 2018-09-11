require 'swagger_helper'

describe "Collections API" do
  path "/collections" do
    get "retrieves collections for the current user" do
      tags 'Private (Sign in required)'
      # TODO accept ttl and xml on default route too
      # not just specific objects
      produces 'application/json'

      # undefined method `per_page' when not set
      let(:per_page) { 1 }
      let(:mode) { 'objects' }

      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        include_context 'rswag_include_spec_output'

        it "should require a sign in" do 
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      context "Signed in user with collections" do
        include_context 'collections_with_objects'

        response "200", "All collections found" do
          include_context 'rswag_include_spec_output'
          run_test! do
            expect(status).to eq(200) 
          end
        end
      end
    end
  end
end
