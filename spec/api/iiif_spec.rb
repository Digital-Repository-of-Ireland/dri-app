require 'swagger_helper'

describe "International Image Interoperability Framework API" do
  # TODO include /iiif/collection/id?
  # Returns same result as iiif/{collection_id}/manifest
  path "/iiif/{id}/manifest" do
    get "retrieves International Image Interoperability Framework manifests for objects" do
      # tags 'IIIF'
      security [ apiKey: [], appId: [] ]
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :pretty, description: 'indent json so it is human readable', 
        in: :query, type: :boolean, default: false, required: false
        
      include_context 'rswag_user_with_collections'

      response "200", "Manifest found" do
        context 'Private manifest with auth' do
          include_context 'rswag_include_json_spec_output'
          let(:user_token) { @example_user.authentication_token }
          let(:user_email) { CGI.escape(@example_user.to_s) }
          let(:id) { @collections.first.id }
          it_behaves_like 'a pretty json response'
        end

        context 'Public manifest' do
          include_context 'rswag_user_with_collections', status: 'published'
          include_context 'rswag_include_json_spec_output', 
            'application/json Unauthorized access to public manifest'
          let(:user_token) { nil }
          let(:user_email) { nil }
          let(:id) { @collections.first.id }
          it_behaves_like 'a pretty json response'
        end
      end

      response "401", "Unauthorized access of private manifest" do
        include_context 'rswag_include_json_spec_output'
        
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.id }
        it_behaves_like 'a json api error'
        it_behaves_like 'a json api 401 error'
        it_behaves_like 'a pretty json response'
      end
      
      response "404", "Manifest not found" do
        include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { 'id_that_does_not_exist' }
        it_behaves_like 'a json api error'
        it_behaves_like 'a json api 404 error'
        it_behaves_like 'a pretty json response'
      end
    end
  end
end

