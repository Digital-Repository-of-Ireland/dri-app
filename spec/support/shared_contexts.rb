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
    # UserGroup::Group.find_or_create_by(
    #   name: SETTING_GROUP_CM, 
    #   description: "collection manager test group"
    # )
    @login_user = FactoryBot.create(:collection_manager)
  end

  after(:all) do
    @login_user.delete
    # UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end
end

