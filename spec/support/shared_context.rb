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
