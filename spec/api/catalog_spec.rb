require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves objects from the catalog" do
      produces "application/json"
      response '200', 'catalog found' do
        run_test! do
          sign_out_all
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response_body).not_to eq auth_error_response
          expect(status).to eq 200
        end
      end
    end
  end
end
