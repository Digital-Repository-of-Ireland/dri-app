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

# @param [Symbol] field
shared_context 'filter_test results exist' do |field: :subject|
  before(:each) do
    # drop draft collections
    # @collections.select! { |col| col.status == 'published' }

    @collections.first.send("#{field}=", ['filter_test'])
    @collections.first.save!

    @collections.last.send("#{field}=", ['other_filter_test'])
    @collections.last.save!
  end
end


# @param [Symbol] field
shared_context 'filter_test results do not exist' do |field: :subject|
  before(:each) do
    @collections.each do |col|
      col.send("#{field}=", ['no match'])
      col.save!
    end    
  end
end
