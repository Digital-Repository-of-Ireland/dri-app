shared_context 'rswag_include_json_spec_output' do |example_name='application/json'|
  after do |example|
    example.metadata[:response][:examples] = { 
      example_name => JSON.parse(
        response.body, 
        symbolize_names: true
      ) 
    }
  end
end

shared_context 'rswag_include_xml_spec_output' do |example_name='application/xml'|
  after do |example|
    example.metadata[:response][:examples] = { 
      example_name => Nokogiri::XML(response.body) 
    }
  end
end

shared_context 'rswag_unauthenticated_request' do
  let(:user_token) { nil }
  let(:user_email) { nil }
  before(:each) do |example|
    sign_out_all
    submit_request(example.metadata)
  end
end

# # TODO create shared context that handles issue with nesting contexts for users
# # i.e. single shared context that handles auth, collections, etc for a given request
# # so that the individual shared_contexts don't rely on being a certain block level 
# # deep to access variables created by other shared contexts

# shared_context 'rswag_authenticated_request' do |collections|
#   before(:each) do
#     # create objects for security params
#     @example_user = FactoryBot.create(:collection_manager)
#     @example_user.create_token
#     @example_user.save!
#   end
#   after(:each) do
#     @example_user.delete
#   end
# end
