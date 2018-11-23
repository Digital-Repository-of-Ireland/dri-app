require 'swagger_helper'

describe "Catalog API" do
  path "/catalog" do
    get "retrieves objects from the catalog" do
      produces 'application/json', 'application/xml', 'application/ttl'
      include_context 'rswag_user_with_collections', status: 'published'

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, type: :string, default: 'objects'
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false

      let(:per_page) { 9 }
      let(:mode)     { 'objects' }

      response '200', 'catalog found' do
        include_context 'sign_out_before_request' do
          include_context 'rswag_include_json_spec_output' do
            it_behaves_like 'a pretty json response'
          end
        end
      end
    end
  end

  path "/catalog/{id}" do
    get "retrieves a specific object from the catalog" do
      produces 'application/json', 'application/xml', 'application/ttl'
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string
      include_context 'rswag_user_with_collections', status: 'published'

      response "200", "Found" do
        context 'Collection' do
          let(:id) { @collections.first.id }
          it_behaves_like 'it has no json licence information'
          include_context 'rswag_include_json_spec_output', 'Found Collection' do
            it_behaves_like 'a pretty json response'
          end
        end
        context 'Object' do
          let(:id) { @collections.first.governed_items.first.id }
          include_context 'rswag_include_json_spec_output', 'Found Object' do
            it_behaves_like 'it has json licence information'
            it_behaves_like 'it has json doi information'
          end
        end
      end
    end
  end
end
