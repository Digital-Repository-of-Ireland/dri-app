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

# shared_context 'rswag_unauthenticated_request' do
#   let(:user_token) { nil }
#   let(:user_email) { nil }
#   before(:each) do |example|
#     sign_out_all
#     submit_request(example.metadata)
#   end
# end

# # depends on @example user existing with authentication_token!
# shared_context 'rswag_token_authenticated_request' do
#   let(:user_token) { @example_user.authentication_token }
#   let(:user_email) { CGI.escape(@example_user.to_s) }
#   before(:each) do |example|
#     sign_out_all
#     submit_request(example.metadata)
#   end
# end

shared_context 'rswag_user_with_collections' do |status: 'draft', num_collections: 2, num_objects: 2|
  before do
    @example_user = create_user
    @collections = []
    if status == 'published'
      @institute = FactoryBot.create(:institute)
      @institute.save
    else
      @institute = nil
    end
    num_collections.times do |i|
      collection = create_collection_for(@example_user, status: status)
      num_objects.times do |j|
        object = create_object_for(
          @example_user, 
          status: status,
          title: "not a duplicate #{j}",
        )
        object.depositing_institute = @institute.name if @institute
        collection.governed_items << object
      end
      collection.depositing_institute = @institute.name if @institute
      collection.manager_users = [@example_user]
      collection.published_at = DateTime.now.strftime("%Y-%m-%d")
      # collection.governing_collection = 'root'
      collection.save
      @collections << collection
    end
  end
  after(:each) do
    @institute.delete if @institute
    @collections.map
    @example_user.delete
  end
end


# @param type [Symbol]
# @param token [Boolean]
# @return user [User]
def create_user(type: :collection_manager, token: true)
  user = FactoryBot.create(type)
  user.create_token if token
  user.save
  user
end

# @param user [User]
# @param type [Symbol]
# @param title [String]
# @param status [String]
# @return collection [DRI::QualifiedDublinCore (Collection)]
def create_collection_for(user, status: 'draft', title: 'test_collection')
  collection = FactoryBot.create(:collection)
  # collection = Collection.new if status == 'published'
  collection[:status] = status
  collection[:creator] = [user.to_s]
  collection[:title] = [title]
  collection[:date] = [DateTime.now.strftime("%Y-%m-%d")]
  collection.apply_depositor_metadata(user.to_s)
  collection.save
  collection
end

# @param user [User]
# @param type [Symbol]
# @param title [String]
# @param status [String]
# @return collection [DRI::QualifiedDublinCore (Object)]
def create_object_for(user, type: :sound, status: 'draft', title: 'test_object')
  object = FactoryBot.create(type)
  object[:status] = status
  object[:title] = [title]
  object.apply_depositor_metadata(user.to_s)
  object.save
  object
end
