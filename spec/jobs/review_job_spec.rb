require 'rails_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding slow: true
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

    @login_user = FactoryBot.create(:collection_manager)

    @collection = FactoryBot.create(:collection)
    @collection[:status] = "draft"
    @collection.save

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryBot.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @subcollection = FactoryBot.create(:collection)
    @subcollection[:status] = "draft"
    @subcollection.governing_collection = @collection
    @subcollection.save

    @collection.governed_items << @object
    @collection.governed_items << @object2
    @collection.save
  end

  after(:each) do
    @object.delete
    @object2.delete
    @collection.delete

    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "run" do
    it "should set all objects status to reviewed" do
      job = ReviewJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform

      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")
    end

     it "should set subcollection status to reviewed if draft" do
      job = ReviewJob.new('test', { 'collection_id' => @subcollection.id, 'user_id' => @login_user.id })
      job.perform

      @subcollection.reload

      expect(@subcollection.status).to eql("reviewed")
    end

    it "should ignore published objects" do
      @published = FactoryBot.create(:sound)
      @published[:status] = "published"
      @published.save

      job = ReviewJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id })
      job.perform

      @object.reload
      @object2.reload

      expect(@object.status).to eql("reviewed")
      expect(@object2.status).to eql("reviewed")
      expect(@published.status).to eql("published")

      @published.delete
    end

    @slow
    it "should handle more than 10 objects", slow: true do
      20.times do
        o = FactoryBot.create(:sound)
        o[:status] = "draft"
        o.save

        @collection.governed_items << o
      end

      @collection.save
      job = ReviewJob.new('test', { 'collection_id' => @collection.id, 'user_id' => @login_user.id})
      job.perform

      expect(ActiveFedora::SolrService.count("collection_id_sim:\"#{@collection.id}\" AND status_ssim:reviewed")).to eq(22)
    end


  end

end
