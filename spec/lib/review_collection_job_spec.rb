require 'spec_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "ReviewCollectionJob" do

  before(:each) do
    @login_user = FactoryGirl.create(:collection_manager)

    @collection = FactoryGirl.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object
    @collection.save

    @subcollection = FactoryGirl.create(:collection)
    @subcollection[:status] = "draft"
    @subcollection.governing_collection = @collection
    @subcollection.save

    @subcollection2 = FactoryGirl.create(:collection)
    @subcollection2[:status] = "draft"
    @subcollection2.governing_collection = @collection
    @subcollection2.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete
  end
  
  describe "run" do
    it "should trigger jobs for subcollections" do
      Resque.should_receive(:enqueue).exactly(3).times
      ReviewCollectionJob.perform(@collection.id, @login_user.id)
    end  
  end

end