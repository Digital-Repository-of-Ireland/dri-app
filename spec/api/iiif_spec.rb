require 'swagger_helper'

describe "International Image Interoperability Framework API" do
  # TODO include /iiif/collection/id?
  # Returns same result as iiif/{collection_id}/manifest
  path "/iiif/{id}/manifest" do
    get "retrieves International Image Interoperability Framework manifests" do
      tags 'Public'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true

      context "Signed in user with collections" do
        include_context 'user_with_collections'

        response "200", "Manifest found" do
          include_context 'rswag_include_json_spec_output', 
            example_name='/iiif/{id}/manifest'
          let(:id) { @collections.first.id }
          run_test!
        end
        response "401", "Unauthorized access of specific manifest" do
          let(:id) { @collections.first.id }
          before { sign_out_all }
          run_test!
        end
        
        response "404", "Manifest not found" do
          include_context 'rswag_include_json_spec_output', 
            example_name='/iiif/{id}/manifest'
          let(:id) { 'id_that_does_not_exist' }
          run_test!
        end
      end
    end
  end
end

