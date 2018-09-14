shared_context 'tmp_assets' do
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
end

shared_context 'collection_manager_user' do
  before(:all) do
    UserGroup::Group.find_or_create_by(
      name: SETTING_GROUP_CM, 
      description: "collection manager test group"
    )
    @login_user = FactoryBot.create(:collection_manager)
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end
end

shared_context 'collections_with_objects' do |num_collections=2, num_objects=2, status='draft'|
  before(:each) do
    @collections = []

    # have to create new user here to grant access to collection
    # otherwise we depend on the context for the user to already exist
    @new_user = FactoryBot.create(:collection_manager)
    sign_in @new_user

    num_collections.times do |i|
      collection = FactoryBot.create(:collection)
      # collection = Collection.new
      collection[:status] = status
      collection[:creator] = [@new_user.to_s]
      collection[:date] = [DateTime.now.strftime("%Y-%m-%d")]
      collection.apply_depositor_metadata(@new_user.to_s)

      # collections must contain objects 
      # in order to take up space on the json output!
      # otherwise docs=[], total_pages=0
      num_objects.times do |j|
        object = FactoryBot.create(:sound)
        object[:status] = status
        object[:title] = ["Not a Duplicate#{j}"]
        object.apply_depositor_metadata(@new_user.to_s)
        object.save
        collection.governed_items << object
      end

      collection.save
      @collections.push(collection)
    end
  end

  after(:each) do
    @collections.map(&:delete)
  end
end

shared_context 'subcollection' do |status='draft'|
  before(:each) do
    @new_user = FactoryBot.create(:collection_manager)
    sign_in @new_user

    @collection = FactoryBot.create(:collection)
    @subcollection = FactoryBot.create(:collection)

    [@collection, @subcollection].each do |c|
      object = FactoryBot.create(:sound)
      object[:status] = status
      object[:title] = ["Not a Duplicate"]
      object[:creator] = [@new_user.email]
      object.apply_depositor_metadata(@new_user.to_s)
      object.save
      c.governed_items << object
      c.apply_depositor_metadata(@new_user.to_s)
    end

    @subcollection.status = status
    @subcollection[:title] = ["Not a Duplicate collection"]
    @subcollection[:creator] = [@new_user.email]
    @subcollection.save
    @subcollection.governing_collection = @collection
    @collection.save
  end
end

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

shared_context 'sign_out_before_request' do
  before do |example|
    sign_out_all
    submit_request(example.metadata)
  end
end

# shared_context 'sign_in_before_request' do
#   before do |example|
#     sign_in @login_user
#     submit_request(example.metadata)
#   end
# end
