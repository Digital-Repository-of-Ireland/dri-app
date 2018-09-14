# # produces xml

# require 'swagger_helper'

# # TODO sparql endpoint spec
# describe "Open Archives Initiative API" do
#   path "/oai" do
#     include_context 'collections_with_objects'
#     get "retrieves open archives initiative data for the dri repository" do
#       tags 'Public'
#       produces 'application/xml'
#       parameter name: :verb, in: :path, :type => :string
#       parameter name: :metadataPrefix, in: :path, :type => :string

#       response "200", "OAI data found" do
#         context 'public access' do
#           include_context 'sign_out_before_request'

#           it 'returns 200 whether the user is signed in or not' do
#             expect(status).to eq(200) # 401 unauthorized
#           end
#         end
#       end
#     end
#   end
# end
