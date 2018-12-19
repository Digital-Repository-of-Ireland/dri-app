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
    @login_user = FactoryBot.create(:collection_manager)
  end

  after(:all) do
    @login_user.destroy
  end
end

shared_context 'doi_config_exists' do
   before(:each) do
    stub_const(
      'DoiConfig',
      OpenStruct.new(
        { 
          :username => "user",
          :password => "password",
          :prefix => '10.5072',
          :base_url => "http://repository.dri.ie",
          :publisher => "Digital Repository of Ireland" 
        }
      )
    )
  end
end


