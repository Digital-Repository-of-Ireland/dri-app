# produces xml

require 'swagger_helper'

# TODO sparql endpoint spec
describe "Open Archives Initiative API" do
  path "/oai" do
    include_context 'collections_with_objects'
    get "retrieves open archives initiative data for the dri repository" do
      tags 'Public'
      produces 'application/xml'
      parameter name: :verb, in: :query, type: :string, required: true,
        enum: [
          'Identify', 'ListRecords', 'ListSets', 
          'ListMetadataFormats', 'ListIdentifiers'
        ]
      parameter name: :metadataPrefix, in: :query, type: :string, 
        required: false, description: 'must be oai_dri for ListRecords and ListIdentifiers'

      let(:verb) { nil }

      response "200", "OAI data found" do
        context 'public access' do
          include_context 'sign_out_before_request'
          include_context 'rswag_include_xml_spec_output',
            example_name="/oai (error missing verb)"

          it 'returns 200 whether the user is signed in or not' do
            expect(status).to eq(200) # 401 unauthorized
          end
        end
        # TODO better test using nokogiri to make sure response 
        # doesn't contain errors
        context 'Identify' do
          include_context 'rswag_include_xml_spec_output',
            example_name="/oai?verb=Identify"
          let(:verb) { 'Identify' }

          # sign_out_before_request handles this in other cases
          before { |example| submit_request(example.metadata) }

          it 'returns 200' do
            expect(status).to eq(200) # 401 unauthorized
          end
        end
      end
    end
  end
end
