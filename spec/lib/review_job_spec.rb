require 'spec_helper'

describe "ReviewJob" do

  before(:each) do
    @collection = FactoryGirl.create(:collection)
    @collection[:status] = ["draft"]
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = ["draft"]
    @object.save

    @object2 = FactoryGirl.create(:sound)
    @object2[:status] = ["draft"]
    @object2.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.save
  end

  after(:each) do
    @object.delete
    @object2.delete
    @collection.delete
  end
  
  describe "run" do
    it "should set all objects status to reviewed" do
      job = ReviewJob.new(@object.governing_collection.id)
      job.run

      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")     
    end

    it "should ignore published objects" do
      @published = FactoryGirl.create(:sound)
      @published[:status] = ["published"]
      @published.save

      job = ReviewJob.new(@object.governing_collection.id)
      job.run

      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")
      expect(@published.status).to eql("published")

      @published.delete
    end

  end
 
end
