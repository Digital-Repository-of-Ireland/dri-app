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
      include_context 'rswag_user_with_collections'

      response "200", "Manifest found" do
        context 'Private manifest with auth' do
          include_context 'rswag_include_json_spec_output'
          let(:user_token) { @example_user.authentication_token }
          let(:user_email) { CGI.escape(@example_user.to_s) }
          let(:id) { @collections.first.id }
          run_test!
        end

        context 'Public manifest' do
          include_context 'rswag_user_with_collections', status: 'published'
          include_context 'rswag_include_json_spec_output', 
            'application/json Unauthorized access to public manifest'
          let(:user_token) { nil }
          let(:user_email) { nil }
          let(:id) { @collections.first.id }
          run_test!
        end
      end

      response "401", "Unauthorized access of private manifest" do
        # TODO same issue as collections 401, not returning error message
        # include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.id }
        run_test!
      end
      
      response "404", "Manifest not found" do
        include_context 'rswag_include_json_spec_output'
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { 'id_that_does_not_exist' }
        run_test!
      end
    end
  end
end

