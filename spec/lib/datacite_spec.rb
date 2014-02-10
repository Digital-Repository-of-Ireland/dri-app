require 'spec_helper'
require 'ostruct'
require 'active_support/core_ext/hash/conversions'
require 'doi/datacite'

describe "DOI::Datacite" do

  DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository" })

  before :each do
    #@object = FactoryGirl.create(:sound)
    @object = Batch.new
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

  it "should create a DOI" do
    datacite = DOI::Datacite.new(@object)
    datacite.doi.should == File.join(File.join(DoiConfig.prefix.to_s, @object.id.sub(':', '.')))
  end

  it "should get the publication year" do
    datacite = DOI::Datacite.new(@object)
    datacite.publication_year.should equal(Date.parse(@object[:published_date].first).year)
  end

  it "should create datacite XML" do
    datacite = DOI::Datacite.new(@object)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    hash["resource"]["titles"]["title"].should == @object.title.first
    hash["resource"]["subjects"]["subject"][0].should == @object.subject[0]
    hash["resource"]["subjects"]["subject"][1].should == @object.subject[1]
  end

end
