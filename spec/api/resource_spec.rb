require 'swagger_helper'

# TODO sparql endpoint spec
describe "Resource API" do
  path "/resource/{id}" do
    include_context 'signed_in_user_with_collections'
    get "retrieves linked data using sparql" do
      tags 'Private (Sign in required)'
      produces 'application/rdf', 'application/ttl'
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string

      # TODO: make api response consistent
      # Return sign in error in turtle format?
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        let(:id) { @collections.first.id }

        it 'returns a 401 when the user is not signed in' do
          expect(status).to eq(401) # 401 unauthorized
        end
      end
    end
  end
end
