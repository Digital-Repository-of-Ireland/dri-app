require 'swagger_helper'

# TODO sparql endpoint spec
describe "Resource API" do
  path "/resource/{id}" do
    include_context 'rswag_user_with_collections'
    get "retrieves linked data using sparql" do
      security [ apiKey: [], appId: [] ]
      produces 'application/rdf', 'application/ttl'

      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string

      # TODO: make api response consistent
      # Return sign in error in turtle format?
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        let(:user_token) { nil }
        let(:user_email) { nil }
        let(:id) { @collections.first.id }
        run_test!
      end
    end
  end
end
