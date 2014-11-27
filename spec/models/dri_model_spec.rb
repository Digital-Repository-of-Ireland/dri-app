require 'spec_helper'

describe Batch do
  it "should have an audio type with the level 1 required metadata fields" do
    @t = Batch.new
    @t.title = nil
    @t.rights = nil
    @t.language = nil
    @t.object_type = ["Audio"]
    @t.should_not be_valid
  end

  it "should not index null date values" do
    @t = Batch.new
    @t.title = "A fake record"
    @t.rights = "Rights"
    @t.creation_date = "null"
    @t.published_date = "null"
    @t.date = "null"
    @t.description = "A fake object"

    solr_doc = @t.to_solr
    solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].should_not include("null")
    solr_doc[Solrizer.solr_name('published_date', :stored_searchable)].should_not include("null")
    solr_doc[Solrizer.solr_name('date', :stored_searchable)].should_not include("null")
  end

  it "should only hide the null values" do
    @t = Batch.new
    @t.title = "A fake record"
    @t.rights = "Rights"
    @t.creation_date = ["2014-10-17", "null"]
    @t.published_date = ["2014-10-17", "null"]
    @t.date = ["2014-10-17", "null"]
    @t.description = "A fake object"

    solr_doc = @t.to_solr
    solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].should_not include("null")
    solr_doc[Solrizer.solr_name('published_date', :stored_searchable)].should_not include("null")
    solr_doc[Solrizer.solr_name('date', :stored_searchable)].should_not include("null")

    solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].should include("2014-10-17")
    solr_doc[Solrizer.solr_name('published_date', :stored_searchable)].should include("2014-10-17")
    solr_doc[Solrizer.solr_name('date', :stored_searchable)].should include("2014-10-17")
  end

  it "should not index null creator values" do
    @t = Batch.new
    @t.title = "A fake record"
    @t.rights = "Rights"
    @t.creator = "null"
    @t.creation_date = "null"
    @t.published_date = "null"
    @t.date = "null"
    @t.description = "A fake object"

    solr_doc = @t.to_solr
    solr_doc[Solrizer.solr_name('creator', :stored_searchable)].should_not include("null")
  end

  it "should only not index null creator values" do
    @t = Batch.new
    @t.title = "A fake record"
    @t.rights = "Rights"
    @t.creator = ["A Creator", "null"]
    @t.creation_date = "null"
    @t.published_date = "null"
    @t.date = "null"
    @t.description = "A fake object"

    solr_doc = @t.to_solr
    solr_doc[Solrizer.solr_name('creator', :stored_searchable)].should_not include("null")
    solr_doc[Solrizer.solr_name('creator', :stored_searchable)].should include("A Creator")
  end

  it "should make a case insensitive check for null" do
    @t = Batch.new
    @t.title = "A fake record"
    @t.rights = "Rights"
    @t.creator = "NuLl"
    @t.date = "2014-10-17"
    @t.description = "A fake object"

    solr_doc = @t.to_solr
    solr_doc[Solrizer.solr_name('creator', :stored_searchable)].should_not include("NuLl")
  end
  
  after(:each) do
    unless @t.new_record?
      @t.delete
    end
  end

end
