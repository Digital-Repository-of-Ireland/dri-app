require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves objects from the catalog" do
      tags 'Public'      
      produces "application/json"

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, type: :string, default: 'objects'

      let(:per_page) { 9 }
      let(:mode)     { 'objects' }

      response '200', 'catalog found' do
        include_context 'sign_out_before_request'
        include_context 'rswag_include_json_spec_output'
          
        it 'returns 200 regardless of whether you are signed in' do
          expect(status).to eq 200
        end
      end
    end
  end
end
