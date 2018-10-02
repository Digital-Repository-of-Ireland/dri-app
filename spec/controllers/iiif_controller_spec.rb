describe IiifController do
  include Devise::Test::ControllerHelpers

   before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
   end

   after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'GET show' do

    let(:collection) { FactoryBot.create(:collection) }
    let(:object) { FactoryBot.create(:image) }

    it "should allow access to public, published image" do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.read_groups_string = 'public'
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'show'
      expect(response.status).to eq(200)
    end

    it "should allow info request for published image" do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'info'
      expect(response.status).to eq(200)
    end

    it 'should not allow access to restricted images' do
      collection.status = 'published'
      collection.save

      object.status = 'published'
      object.read_groups_string = ''
      object.governing_collection = collection
      object.save
      
      get :show, id: "#{object.id}:test", method: 'show'
      expect(response.status).to eq(401)
    end

  end

  describe 'GET manifest' do

    let(:collection) { FactoryBot.create(:collection) }
    let(:object) { FactoryBot.create(:image) }
    let(:login_user) { FactoryBot.create(:admin) }

    it 'should return a valid manifest for an object' do
      sign_in login_user

      get :manifest, id: object.id, format: :json
      expect { JSON.parse(response.body) }.not_to raise_error
    end

  end

end
