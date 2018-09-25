require 'swagger_helper'

describe "Open Archives Initiative API" do
  path "/oai" do
    get "retrieves open archives initiative data for the dri repository" do
      description 'the html version of this endpoint includes links to valid requests'
      # tags 'Open Archives Initiative'
      produces 'application/xml'
      include_context 'rswag_user_with_collections'
      parameter name: :verb, in: :query, type: :string, required: true,
        enum: [
          'Identify', 'ListRecords', 'ListSets', 
          'ListMetadataFormats', 'ListIdentifiers'
        ]
      parameter name: :metadataPrefix, in: :query, type: :string, 
        required: false, description: 'must be oai_dri for ListRecords and ListIdentifiers'

      let(:verb) { nil }
      # must not be set at all since it'll create the following request
      # /oai?verb=&metadataPrefix= which returns
      # The request includes illegal arguments
      # let(:metadataPrefix) { nil }

      response "200", "OAI data found" do
        context 'public access' do
          include_context 'sign_out_before_request'
          include_context 'rswag_include_xml_spec_output',
            example_name="/oai (error missing verb)"
          run_test!
        end
        # TODO better test using nokogiri to make sure response 
        # doesn't contain errors
        { 
          'Identify' => {verb: 'Identify'},
          'List records' => {verb: 'ListRecords', metadataPrefix: 'oai_dri'},
          'List sets' => {verb: 'ListSets'},
          'List Metadata formats' => {verb: 'ListMetadataFormats'},
          'List identifiers' => {verb: 'ListIdentifiers', metadataPrefix: 'oai_dri'}
        }.each do |k, v|
          context k do
            api_args = v.map &->(k,v) {"#{k}=#{v}"}
            include_context 'sign_out_before_request'
            include_context 'rswag_include_xml_spec_output',
              example_name="/oai?#{api_args.join("&")}"
            v.each { |symbol, value|  let(symbol) { value } }
            before { |example| submit_request(example.metadata) }
            run_test!
          end
        end
      end
    end
  end
end
