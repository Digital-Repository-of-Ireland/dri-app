require 'ostruct'
require 'active_support/core_ext/hash/conversions'

describe "DataciteDoi" do

  before(:each) do
    stub_const(
        'DoiConfig',
        OpenStruct.new(
          { :username => "user",
            :password => "password",
            :prefix => '10.5072',
            :base_url => "http://repository.dri.ie",
            :publisher => "Digital Repository of Ireland" }
            )
        )

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
    @object[:resource_type] = ["Sound"]
    @object.save
  end

  after(:each) do
    @object.delete
  end

  it "should create a DOI" do
    datacite = DataciteDoi.create(object_id: @object.id)
    datacite.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}"))
  end

  it "should create datacite XML" do
    datacite = DataciteDoi.create(object_id: @object.id)
    xml = datacite.to_xml
    
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    hash["resource"]["titles"]["title"].should == @object.title.first
    hash["resource"]["creators"]["creator"]["creatorName"] == @object.creator.first
    hash["resource"]["publisher"].should == DoiConfig.publisher
    hash["resource"]["publicationYear"].should == "#{Time.now.year}"
  end

  it 'should use roles if no creator' do
    @creator = DRI::Batch.with_standard :qdc
    @creator[:title] = ["An Audio Title"]
    @creator[:description] = ["This is an Audio file"]
    @creator[:rights] = ["This is a statement about the rights associated with this object"]
    @creator[:role_hst] = ["Collins, Michael"]
    @creator[:creation_date] = ["1916-01-01"]
    @creator[:resource_type] = ["Sound"]
    @creator.save

    datacite = DataciteDoi.create(object_id: @creator.id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)

    hash["resource"]["creators"]["creator"]["creatorName"] == @creator.role_hst[0]

    @creator.delete
    datacite.delete
  end

  it "should require update if title changed" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: ["A modified title"], creator: @object.creator }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be true
  end

  it "should require update if creator changed" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: @object.title, creator: ["A. Body"] }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be true
  end

  it "should not need an update if no change" do
    datacite = DataciteDoi.create(object_id: @object.id)
    fields = { title: @object.title, creator: @object.creator }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be false
  end
 
  it "should add version numbers to doi" do
    datacite = DataciteDoi.create(object_id: @object.id)
    
    datacite.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}"))

    datacite2 = DataciteDoi.create(object_id: @object.id)
    datacite2.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}-1"))

    datacite3 = DataciteDoi.create(object_id: @object.id)
    datacite3.doi.should == File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}-2"))
  end

end
