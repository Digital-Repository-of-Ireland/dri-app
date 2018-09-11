require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves objects from the catalog" do
      produces "application/json"
      response '200', 'catalog found' do
        before do |example|
          sign_out_all
          submit_request(example.metadata)
        end

        after do |example|
          example.metadata[:response][:examples] = { 'application/json' => JSON.parse(response.body, symbolize_names: true) }
        end
          
        it 'returns 200 regardless of whether you are signed in' do
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).not_to eq auth_error_response
          expect(status).to eq 200
        end
      end
    end
  end
end
