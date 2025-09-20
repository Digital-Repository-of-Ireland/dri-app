require 'rails_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "DeleteCollectionJob" do

  before(:each) do
    @collection = FactoryBot.create(:collection)

    @object = FactoryBot.create(:image)
    @object[:status] = "draft"
    @object.save
  end

  describe "run" do
    it "should delete a collection and governed_items" do
      @collection.governed_items << @object
      @collection.save
      job = DeleteCollectionJob.new(@collection.alternate_id)
      job.run

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be false
      expect(DRI::Identifier.object_exists?(@collection.alternate_id)).to be false
    end

    it "should delete objects with governing collection" do
      @object.governing_collection = @collection
      @object.save
      job = DeleteCollectionJob.new(@collection.alternate_id)
      job.run

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be false
      expect(DRI::Identifier.object_exists?(@collection.alternate_id)).to be false
    end

    it "should cleanup MOAB for draft objects" do
      @object.governing_collection = @collection
      @object.save

      preservator = Preservation::Preservator.new(@object)
      expect(File.exist?(preservator.aip_dir(@object.alternate_id))).to be true

      job = DeleteCollectionJob.new(@collection.alternate_id)
      job.run

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be false
      expect(DRI::Identifier.object_exists?(@collection.alternate_id)).to be false
      expect(File.exist?(preservator.aip_dir(@object.alternate_id))).to be false
    end

    it "should not cleanup MOAB for published objects" do
      @object.governing_collection = @collection
      @object.save

      @collection.status = "published"
      @collection.save

      preservator = Preservation::Preservator.new(@object)
      expect(File.exist?(preservator.aip_dir(@object.alternate_id))).to be true

      job = DeleteCollectionJob.new(@collection.alternate_id)
      job.run

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be false
      expect(DRI::Identifier.object_exists?(@collection.alternate_id)).to be false
      expect(File.exist?(preservator.aip_dir(@object.alternate_id))).to be true
    end

  end

end
