require 'swagger_helper'

describe "International Image Interoperability Framework API" do
  path "/iiif/{id}/manifest" do
    get "retrieves International Image Interoperability Framework manifests" do
      tags 'Public'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true

      context "Signed in user with collections" do
        include_context 'collections_with_objects'

        response "200", "Manifest found" do
          include_context 'rswag_include_json_spec_output', 
            example_name='/iiif/{id}/manifest'
          let(:id) { @collections.first.id }
          run_test! do
            expect(status).to eq(200) 
          end
        end
        # TODO possibly return 404 instead of 500?
        response "500", "Manifest not found" do
          let(:id) { 'id_that_does_not_exist' }
          run_test!
        end
      end
    end
  end
end

