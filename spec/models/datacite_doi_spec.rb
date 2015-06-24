require 'spec_helper'
require 'ostruct'
require 'active_support/core_ext/hash/conversions'
require 'doi/datacite'

describe "DataciteDoi" do

  before(:all) do
    DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository", :publisher => "Digital Repository of Ireland" })

    @object = DRI::Batch.with_standard :qdc
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
    @object[:type] = ["Sound"]
    @object.save
  end

  after(:all) do
    @object.delete
  end

  it "should create a DOI" do
    datacite = DataciteDoi.new(object_id: @object.id)
    datacite.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{@object.id}"))
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

  it "should allow versions" do
    datacite = DataciteDoi.create(object_id: @object.id)

    datacite2 = DataciteDoi.create(object_id: @object.id, version: 1)

    expect(DataciteDoi.where(object_id: @object.id).current.version).to eq 1
  end

  it "should determine if an update is required" do
    @object2 = DRI::Batch.with_standard :qdc
    @object2[:title] = ["An Audio Title"]
    @object2[:rights] = ["This is a statement about the rights associated with this object"]
    @object2[:role_hst] = ["Collins, Michael"]
    @object2[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object2[:language] = ["ga"]
    @object2[:description] = ["This is an Audio file"]
    @object2[:published_date] = ["1916-04-01"]
    @object2[:creation_date] = ["1916-01-01"]
    @object2[:source] = ["CD nnn nuig"]
    @object2[:geographical_coverage] = ["Dublin"]
    @object2[:temporal_coverage] = ["1900s"]
    @object2[:subject] = ["Ireland","something else"]
    @object2[:type] = ["Sound"]
    @object2.save    

    datacite = DataciteDoi.create(object_id: @object.id)
    expect(datacite.requires_update?(@object2)).to be false

    @object2.title = ["A modified title"]
    @object2.save

    expect(datacite.requires_update?(@object2)).to be true

    @object2.delete
  end

end
