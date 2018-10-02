describe DRI::Batch do
  it "should have an audio type with the level 1 required metadata fields" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = nil
    @t.rights = nil
    @t.language = nil
    @t.object_type = ["Audio"]
    @t.should_not be_valid
  end

  it "should not index null date values" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)]).to_not include("null")
    expect(solr_doc[Solrizer.solr_name('published_date', :stored_searchable)]).to_not include("null")
    expect(solr_doc[Solrizer.solr_name('date', :stored_searchable)]).to_not include("null")
  end

  it "should only hide the null values" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2014-10-17", "null"]
    @t.published_date = ["2014-10-17", "null"]
    @t.date = ["2014-10-17", "null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].size).to eq(1)
    expect(solr_doc[Solrizer.solr_name('published_date', :stored_searchable)].size).to eq(1)
    expect(solr_doc[Solrizer.solr_name('date', :stored_searchable)].size).to eq(1)

    expect(solr_doc[Solrizer.solr_name('creation_date', :stored_searchable)].any?{ |val| /2014-10-17/ =~ val}).to be true
    expect(solr_doc[Solrizer.solr_name('published_date', :stored_searchable)].any?{ |val| /2014-10-17/ =~ val}).to be true
    expect(solr_doc[Solrizer.solr_name('date', :stored_searchable)].any?{ |val| /2014-10-17/ =~ val}).to be true
  end

  it "should not index null creator values" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["null"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc[Solrizer.solr_name('creator', :stored_searchable)]).to_not include("null")
  end

  it "should only not index null creator values" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["A Creator", "null"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc[Solrizer.solr_name('creator', :stored_searchable)]).to_not include("null")
    expect(solr_doc[Solrizer.solr_name('creator', :stored_searchable)]).to include("A Creator")
  end

  it "should make a case insensitive check for null" do
    @t = DRI::Batch.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["NuLl"]
    @t.date = ["2014-10-17"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc[Solrizer.solr_name('creator', :stored_searchable)]).to_not include("NuLl")
  end
  
  after(:each) do
    unless @t.new_record?
      @t.delete
    end
  end

end
