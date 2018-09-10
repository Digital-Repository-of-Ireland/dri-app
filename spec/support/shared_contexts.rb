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

# num_items :number, item_type :symbol, status :string
shared_context 'collection' do |num_items=1, item_type=:sound, status='draft'|
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @collection[:status] = status

    num_items.times do |i|
      object = FactoryBot.create(item_type)
      object[:status] = status
      object[:title] = ["Not a Duplicate#{i}"]
      object.save
      @collection.governed_items << object
    end

    @collection.save
  end

  after(:each) do
    @collection.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
end

shared_context 'collections' do |num_collections=2, status='draft'|
  before(:each) do
    @collections = []
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    # have to create new user here to grant access to collection
    @new_user = FactoryBot.create(:collection_manager)
    sign_in @new_user

    num_collections.times do |i|
      collection = FactoryBot.create(:collection)
      # collection = Collection.new
      collection[:status] = status
      collection[:creator] = [@new_user.to_s]
      collection[:date] = [DateTime.now.strftime("%Y-%m-%d")]
      collection.licence = "All Rights Reserved"
      collection.apply_depositor_metadata(@new_user.to_s)
      collection.manager_users_string = @new_user.to_s
      collection.manager_groups_string = @new_user.to_s
      collection.discover_groups_string = 'draft'
      collection.discover_groups_string = 'draft'
      collection.discover_users_string = 'draft'
      collection.read_groups_string = 'draft'
      collection.read_users_string = 'draft'
      collection.edit_groups_string = 'draft'
      collection.edit_users_string = 'draft'
      collection.master_file_access = 'draft'

      # collections must contain items 
      # in order to take up space on the json output!
      # otherwise docs=[], page_count=0
      object = FactoryBot.create(:sound)
      object[:status] = status
      object[:title] = ["Not a Duplicate#{i}"]
      object.save
      collection.governed_items << object

      collection.save
      @collections.push(collection)
    end
  end

  after(:each) do
    @collections.map(&:delete)
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
end
