require 'spec_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "PublishCollectionJob" do

  before do
    PublishCollectionJob.any_instance.stub(:completed)
  end

  before(:each) do
    @login_user = FactoryGirl.create(:collection_manager)

    @collection = FactoryGirl.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = "reviewed"
    @object.save

    @collection.governed_items << @object
    @collection.save

    @subcollection = FactoryGirl.create(:collection)
    @subcollection[:status] = "reviewed"
    @subcollection.governing_collection = @collection
    @subcollection.save

    @subcollection2 = FactoryGirl.create(:collection)
    @subcollection2[:status] = "reviewed"
    @subcollection2.governing_collection = @collection
    @subcollection2.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete
  end
  
  describe "perform" do
    it "should trigger jobs for subcollections" do
      PublishJob.should_receive(:create).exactly(3).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

    it "should trigger jobs for published subcollections" do
      @subcollection[:status] = "published"
      @subcollection.save

      PublishJob.should_receive(:create).exactly(3).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

    it "should not trigger jobs for draft subcollections" do
      @subcollection[:status] = "draft"
      @subcollection.save

      PublishJob.should_receive(:create).exactly(2).times
      job = PublishCollectionJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform
    end

  end

end
