require 'swagger_helper'

describe "Get Objects API" do
  path "/graphql" do
    post "retrieves published objects" do
      # TODO: add auth!
      produces 'application/json'
      consumes 'application/json'

      parameter name: :query, description: 'graphql query body',
                in: :body, 
                schema: { 
                  type: :hash, 
                  items: { type: :object },
                  # example: { "query": { "allCollections(filter:{titleContains:\"knowth\"})": "" } }
                  example: { "query": "{ allCollections(first:5) { id, title } }" }
                }

      include_context 'rswag_user_with_collections', status: 'published', num_collections: 2

      response "200", "Objects found" do
        context 'get objects' do
          let(:query) { { query: "{ allCollections(first:1) { id, title } }" } }
          # let(:query) { { query: "{ allCollections { id, title } }" } }
          include_context 'rswag_include_json_spec_output' do
            run_test! do
              num_results = JSON.parse(response.body)['data']['allCollections'].size
              expect(num_results).to eq(1)              
            end
          end
        end
      end
    end
  end
end
