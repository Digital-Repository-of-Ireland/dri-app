require 'rails_helper'

describe DRI::DigitalObject do
  it "should have an audio type with the level 1 required metadata fields" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = nil
    @t.rights = nil
    @t.language = nil
    @t.type = ["Audio"]
    expect(@t).to_not be_valid
  end

  it "should not index null date values" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc['creation_date_tesim']).to_not include("null")
    expect(solr_doc['published_date_tesim']).to_not include("null")
    expect(solr_doc['date_tesim']).to_not include("null")
  end

  it "should only hide the null values" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creation_date = ["2014-10-17", "null"]
    @t.published_date = ["2014-10-17", "null"]
    @t.date = ["2014-10-17", "null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc['creation_date_tesim'].size).to eq(1)
    expect(solr_doc['published_date_tesim'].size).to eq(1)
    expect(solr_doc['date_tesim'].size).to eq(1)

    expect(solr_doc['creation_date_tesim'].any?{ |val| /2014-10-17/ =~ val}).to be true
    expect(solr_doc['published_date_tesim'].any?{ |val| /2014-10-17/ =~ val}).to be true
    expect(solr_doc['date_tesim'].any?{ |val| /2014-10-17/ =~ val}).to be true
  end

  it "should not index null creator values" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["null"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc['creator_tesim']).to_not include("null")
  end

  it "should only not index null creator values" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["A Creator", "null"]
    @t.creation_date = ["null"]
    @t.published_date = ["null"]
    @t.date = ["null"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc['creator_tesim']).to_not include("null")
    expect(solr_doc['creator_tesim']).to include("A Creator")
  end

  it "should make a case insensitive check for null" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["NuLl"]
    @t.date = ["2014-10-17"]
    @t.description = ["A fake object"]

    solr_doc = @t.to_solr
    expect(solr_doc['creator_tesim']).to_not include("NuLl")
  end

  it "should index the correct number of files" do
    @t = DRI::DigitalObject.with_standard :qdc
    @t.title = ["A fake record"]
    @t.rights = ["Rights"]
    @t.creator = ["A Creator"]
    @t.date = ["2014-10-17"]
    @t.description = ["A fake object"]
    @t.type = ["Image"]
    @t.save

    11.times do
      generic_file = FactoryBot.create(:generic_png_file)
      generic_file.digital_object = @t
      generic_file.save
    end
    @t.reload
    solr_doc = @t.to_solr
    expect(solr_doc['file_count_isi']).to eq 11
  end

  after(:each) do
    unless @t.new_record?
      @t.destroy
    end
  end
end
