require 'spec_helper'
require 'ostruct'
require 'active_support/core_ext/hash/conversions'

describe "DataciteDoi" do

  before(:all) do
    DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository", :publisher => "Digital Repository of Ireland" })

    @object = DRI::Batch.with_standard :qdc
    @object[:title] = ["An Audio Title"]
    @object[:creator] = ["A. N. Other"]
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
    @object[:type] = ["Sound"]
    @object.save
  end

  after(:all) do
    @object.delete
  end

  it "should create a DOI" do
    datacite = DataciteDoi.new(object_id: @object.id)
    datacite.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}"))
  end

  it "should get the publication year" do
    datacite = DataciteDoi.new(object_id: @object.id)
    datacite.publication_year.should equal(Time.now.year)
  end

  it "should create datacite XML" do
    datacite = DataciteDoi.new(object_id: @object.id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    hash["resource"]["titles"]["title"].should == @object.title.first
    hash["resource"]["subjects"]["subject"][0].should == @object.subject[0]
    hash["resource"]["subjects"]["subject"][1].should == @object.subject[1]
    hash["resource"]["publisher"].should == DoiConfig.publisher
    hash["resource"]["descriptions"]["description"].should == @object.description.first
    hash["resource"]["dates"]["date"][0].should == @object.creation_date.first
    hash["resource"]["dates"]["date"][1].should == @object.published_date.first
    hash["resource"]["rights"].should == @object.rights.first
  end

  it "should require update if title changed" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: ["A modified title"], creator: @object.creator }
    expect(datacite.update?(fields)).to be true
  end

  it "should require update if creator changed" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: @object.title, creator: ["A. Body"] }
    expect(datacite.update?(fields)).to be true
  end

  it "should not need an update if no change" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: @object.title, creator: @object.creator }
    expect(datacite.update?(fields)).to be false
  end

end
