require 'spec_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "ReviewJob" do

  before(:each) do
    @login_user = FactoryGirl.create(:collection_manager)

    @collection = FactoryGirl.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryGirl.create(:sound)
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryGirl.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.save
  end

  after(:each) do
    @object.delete
    @object2.delete
    @collection.delete

    @login_user.delete
  end
  
  describe "run" do
    it "should set all objects status to reviewed" do
      ReviewJob.perform(@object.governing_collection.id, @login_user.id)
      
      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")     
    end

    it "should ignore published objects" do
      @published = FactoryGirl.create(:sound)
      @published[:status] = "published"
      @published.save

      ReviewJob.perform(@object.governing_collection.id, @login_user.id)
      
      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")
      expect(@published.status).to eql("published")

      @published.delete
    end

    it "should review sub-collections" do
      @subcollection = FactoryGirl.create(:collection)
      @subcollection[:status] = "draft"
      @subcollection.save

      @subobject = FactoryGirl.create(:sound)
      @subobject[:status] = "draft"
      @subobject.save

      @subcollection.governed_items << @subobject
      @subcollection.governing_collection = @collection
      @subcollection.save

      ReviewJob.perform(@subcollection.id, @login_user.id)

      @subobject.reload
      @subcollection.reload

      expect(@subobject.status).to eql("reviewed")
      expect(@subcollection.status).to eql("reviewed")

      @subcollection.delete
    end

    @slow
    it "should handle more than 10 objects", :slow => true do
      20.times do
        o = FactoryGirl.create(:sound)
        o[:status] = "draft"
        o.save

        @collection.governed_items << o
      end

      @collection.save
      ReviewJob.perform(@collection.id, @login_user.id)
            
      expect(ActiveFedora::SolrService.count("collection_id_sim:\"#{@collection.id}\" AND status_ssim:reviewed")).to eq(22)
    end     
      

  end
 
end
