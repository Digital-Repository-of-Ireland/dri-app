require 'rails_helper'

describe 'UpdateAncestorJob' do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
   
    @collection = FactoryBot.create(:collection)
    @object = FactoryBot.create(:sound)
   
    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @collection.destroy

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'run' do
    it "should update collection\'s objects" do
      allow(Resque).to receive(:enqueue)

      @collection.title = "edited"
      @collection.save

      UpdateAncestorJob.perform(@collection.alternate_id)
   
      doc = SolrDocument.find(@object.alternate_id)
      expect(doc['ancestor_title_tesim']).to eql(['edited'])
    end
  end
end
