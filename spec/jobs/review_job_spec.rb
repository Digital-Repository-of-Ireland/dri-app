require 'rails_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "ReviewJob" do

  before do
    allow_any_instance_of(ReviewJob).to receive(:completed)
    allow_any_instance_of(ReviewJob).to receive(:set_status)
    allow_any_instance_of(ReviewJob).to receive(:at)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

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
    @collection.destroy

    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end
  
  describe "run" do
    it "should set all objects status to reviewed" do
      job = ReviewJob.new('test', { 'collection_id' => @collection.noid, 'user_id' => @login_user.id })
      job.perform
      
      @object.reload
      @object2.reload

      expect(@object.status).to eq("reviewed")
      expect(@object2.status).to eq("reviewed")     
    end

    it "should ignore published objects" do
      @published = FactoryGirl.create(:sound)
      @published[:status] = "published"
      @published.save

      job = ReviewJob.new('test', { 'collection_id' => @collection.noid, 'user_id' => @login_user.id })
      job.perform
      
      @object.reload
      @object2.reload

      expect(@object.status).to eq("reviewed")
      expect(@object2.status).to eq("reviewed")
      expect(@published.status).to eq("published")

      @published.delete
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
      job = ReviewJob.new('test', { 'collection_id' => @collection.noid, 'user_id' => @login_user.id})
      job.perform
            
      expect(ActiveFedora::SolrService.count("collection_id_sim:\"#{@collection.noid}\" AND status_ssim:reviewed")).to eq(22)
    end     
      

  end
 
end
