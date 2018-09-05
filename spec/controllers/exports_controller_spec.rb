describe ExportsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'create' do
    
    before(:each) do
      @login_user = FactoryBot.create(:admin)
      sign_in @login_user
    end

    after(:each) do
      @login_user.delete
    end

    it 'should start an export' do
      @collection = FactoryBot.create(:collection)
      @request.env['HTTP_REFERER'] = "/collections/#{@collection.id}/export/new"
            
      expect(Resque).to receive(:enqueue).once
      post :create, id: @collection.id
    end
  end
end
