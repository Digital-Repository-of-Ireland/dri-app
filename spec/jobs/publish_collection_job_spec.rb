require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "PublishCollectionJob" do

  before do
    expect_any_instance_of(PublishCollectionJob).to receive(:completed)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)

    @collection = FactoryBot.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryBot.create(:sound)
    @object[:status] = "reviewed"
    @object.save

    @collection.governed_items << @object
    @collection.save

    @subcollection = FactoryBot.create(:collection)
    @subcollection[:status] = "reviewed"
    @subcollection.governing_collection = @collection
    @subcollection.save

    @subcollection2 = FactoryBot.create(:collection)
    @subcollection2[:status] = "reviewed"
    @subcollection2.governing_collection = @collection
    @subcollection2.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
  
  describe "perform" do
    it "should trigger jobs for subcollections" do
      expect(PublishJob).to receive(:create).exactly(3).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

    it "should trigger jobs for published subcollections" do
      @subcollection[:status] = "published"
      @subcollection.save

      expect(PublishJob).to receive(:create).exactly(3).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

    it "should not trigger jobs for draft subcollections" do
      @subcollection[:status] = "draft"
      @subcollection.save

      expect(PublishJob).to receive(:create).exactly(2).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

  end

end
