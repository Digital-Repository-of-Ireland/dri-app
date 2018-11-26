# rswag / api shared contexts
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

shared_context 'rswag_user_with_collections' do |status: 'draft', num_collections: 2, num_objects: 2, subcollection: true, doi: true, docs: true|
  include_context 'tmp_assets'
  before(:each) do
    @licence = Licence.create(
      name: 'test', description: 'this is a test', url: 'http://example.com'
    )
    
    @example_user = create_user
    @collections  = []
    @dois         = []
    @docs         = []
    @institute    = institute(status)

    num_collections.times do |i|
      collection = create_collection_for(@example_user, status: status)
      collection.licence = @licence.name
      
      if docs
        doc = FactoryBot.create(:documentation)
        collection.documentation_object_ids = doc.id
        @docs << doc
      end
      
      num_objects.times do |j|
        object = create_object_for(
          @example_user,
          status: status,
          title: "not a duplicate #{i}#{j}",
        )
        object.depositing_institute = @institute.name if @institute
        collection.governed_items << object
        @dois << DataciteDoi.create(object_id: object.id) if doi
      end
      collection.depositing_institute = @institute.name if @institute
      collection.manager_users = [@example_user]
      collection.published_at = DateTime.now.strftime("%Y-%m-%d")
      collection.save
      @collections << collection
    end
    @collections << create_subcollection_for(@example_user) if subcollection
    sign_out_all # just to make sure requests aren't using session
  end
  after(:each) do
    @licence.destroy
    @institute.delete if @institute
    @example_user.delete
    @dois.map(&:delete)
    # issue with nested examples e.g iiif_spec
    # possibly check for ldp gone before delete?
    # @collections.map(&:delete)
    @collections.each do |c|
      # try to destroy collection if it still exists, otherwise do nothing
      c.destroy rescue nil
    end
  end
end

shared_context 'sign_out_before_request' do
  before do |example|
    sign_out_all
    submit_request(example.metadata)
  end
end

# TODO move methods in helper module
# Need to ensure it gets loaded before shared_examples / contexts though

# @param [String] status
# @return [Institute] || nil
def institute(status)
  if status == 'published'
    org = FactoryBot.create(:institute)
    org.save
    org
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
# @return collection containing subcollection [DRI::QualifiedDublinCore (Collection)]
def create_subcollection_for(user, status: 'draft')
  collection = create_collection_for(user, status: status)
  subcollection = create_collection_for(user, status: status, title: 'subcollection')
  subcollection.governing_collection = collection

  [collection, subcollection].each do |c|
    c.governed_items << create_object_for(user, status: status)
    c.save
  end

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
