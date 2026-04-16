require 'rails_helper'

describe "UpdateDescendantsJob" do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)  
    @object = FactoryBot.create(:sound)
 
    @collection.governed_items << @object
    @collection.save

    @subcollection = FactoryBot.create(:collection)
    @subcollection.governing_collection = @collection
    @subcollection.save

    @subcollection2 = FactoryBot.create(:collection)
    @subcollection2.governing_collection = @collection
    @subcollection2.save
  end

  after(:each) do
    @collection.destroy
    
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "perform" do
    it "should trigger jobs for subcollections" do
      expect(Resque).to receive(:enqueue).exactly(3).times
      UpdateDescendantsJob.perform(@collection.alternate_id)
    end
  end
end
