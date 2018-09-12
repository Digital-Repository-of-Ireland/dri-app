require 'solr/query'

describe 'FixityJob' do
  
  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)

    @collection = FactoryBot.create(:collection)
    @collection.save

    @object = FactoryBot.create(:sound)
    @object.save

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @object.delete
    @collection.delete
   
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'run' do
    it "should set create a FixityCheck for a collection\'s objects" do
      expect{ FixityJob.perform(@collection.id) }.to change(FixityCheck, :count).by(1)
      expect(FixityCheck.find_by(object_id: @object.id).verified).to be true
    end
  end
end
