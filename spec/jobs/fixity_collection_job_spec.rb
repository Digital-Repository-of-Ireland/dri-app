require 'rails_helper'

describe "FixityCollectionJob" do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)

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

    @report = FixityReport.create(collection_id: @collection_id)
  end

  after(:each) do
    @collection.delete
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "perform" do
    it "should trigger jobs for subcollections" do
      expect(Resque).to receive(:enqueue).exactly(3).times
      FixityCollectionJob.perform(@report.id, @collection.noid, @login_user.id)
    end
  end

end
