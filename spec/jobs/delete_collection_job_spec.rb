require 'rails_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "DeleteCollectionJob" do

  before(:each) do
    @collection = DRI::DigitalObject.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:creator] = ["Creator"]
    @collection[:resource_type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection[:status] = "draft"
    @collection.save

    @object = DRI::DigitalObject.with_standard :qdc
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:source] = ["CD nnn nuig"]
    @object[:geographical_coverage] = ["Dublin"]
    @object[:temporal_coverage] = ["1900s"]
    @object[:subject] = ["Ireland","something else"]
    @object[:resource_type] = ["Sound"]
    @object[:status] = "reviewed"
    @object.save
  end
  
  describe "run" do
    it "should delete a collection and governed_items" do
      @collection.governed_items << @object
      @collection.save
      job = DeleteCollectionJob.new(@collection.noid)
      job.run

      expect(DRI::Identifier.object_exists?(@object.noid)).to be false
      expect(DRI::Identifier.object_exists?(@collection.noid)).to be false
    end

    it "should delete objects with governing collection" do
      @object.governing_collection = @collection
      @object.save
      job = DeleteCollectionJob.new(@collection.noid)
      job.run

      expect(DRI::Identifier.object_exists?(@object.noid)).to be false
      expect(DRI::Identifier.object_exists?(@collection.noid)).to be false
    end

  end
 
end
