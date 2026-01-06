require 'rails_helper'
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

    @object = DRI::DigitalObject.with_standard :qdc
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
    @object.destroy
  end

  it "should create a DOI" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    expect(datacite.doi).to eq File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}"))
  end

  it "should create datacite XML" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["titles"]["title"]).to eq @object.title.first
    expect(hash["resource"]["creators"]["creator"]["creatorName"]).to eq @object.creator.first
    expect(hash["resource"]["publisher"]).to eq DoiConfig.publisher
    expect(hash["resource"]["publicationYear"]).to eq "#{Time.now.year}"
  end

  it "should create datacite XML for a documentation object" do
    doc_obj = FactoryBot.create(:documentation)
    datacite = DataciteDoi.create(object_id: doc_obj.alternate_id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["titles"]["title"]).to eq doc_obj.title.first
    expect(hash["resource"]["creators"]["creator"]["creatorName"]).to eq doc_obj.creator.first
    expect(hash["resource"]["publisher"]).to eq DoiConfig.publisher
    expect(hash["resource"]["publicationYear"]).to eq "#{Time.now.year}"
  end

  it "should include resourcetype in XML" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["resourceType"]["resourceTypeGeneral"]).to eq @object.type.first
  end

  it "should include resourcetype for 3D in XML" do
    @object.type = "3d"
    @object.save
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(doc.at('resourceType')['resourceTypeGeneral']).to eq "Other"
    expect(hash["resource"]["resourceType"]).to eq "3D"
  end

  it "should use audiovisual for movingImage in XML" do
    @object.type = "movingImage"
    @object.save
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["resourceType"]["resourceTypeGeneral"]).to eq "AudioVisual"
  end

  it "should use audiovisual for video in XML" do
    @object.type = "Video"
    @object.save
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["resourceType"]["resourceTypeGeneral"]).to eq "AudioVisual"
  end

  it "should use sound for audio in XML" do
    @object.type = "Audio"
    @object.save
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    xml = datacite.to_xml
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["resourceType"]["resourceTypeGeneral"]).to eq "Sound"
  end

  it 'should use roles if no creator' do
    @creator = DRI::DigitalObject.with_standard :qdc
    @creator[:title] = ["An Audio Title"]
    @creator[:description] = ["This is an Audio file"]
    @creator[:rights] = ["This is a statement about the rights associated with this object"]
    @creator[:role_hst] = ["Collins, Michael"]
    @creator[:creation_date] = ["1916-01-01"]
    @creator[:resource_type] = ["Sound"]
    @creator.save

    datacite = DataciteDoi.create(object_id: @creator.alternate_id)
    xml = datacite.to_xml

    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)

    hash["resource"]["creators"]["creator"]["creatorName"] == @creator.role_hst[0]

    @creator.delete
    datacite.delete
  end

  it "should require update if title changed" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    fields = { title: ["A modified title"], creator: @object.creator }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be true
  end

  it "should require update if creator changed" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    fields = { title: @object.title, creator: ["A. Body"] }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be true
  end

  it "should not need an update if no change" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    fields = { title: @object.title, creator: @object.creator }
    datacite.update_metadata(fields)
    expect(datacite.changed?).to be false
  end

  it "should handle a nil resource type" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)
    datacite.doi_metadata.resource_type = nil
    datacite.save
    datacite.reload

    xml = datacite.to_xml
    doc = Nokogiri::XML(xml)
    hash = Hash.from_xml(doc.to_s)
    expect(hash["resource"]["resourceType"]["resourceTypeGeneral"]).to eq "Sound"
  end

  it "should add version numbers to doi" do
    datacite = DataciteDoi.create(object_id: @object.alternate_id)

    expect(datacite.doi).to eq File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}"))

    datacite2 = DataciteDoi.create(object_id: @object.alternate_id)
    expect(datacite2.doi).to eq File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}-1"))

    datacite3 = DataciteDoi.create(object_id: @object.alternate_id)
    expect(datacite3.doi).to eq File.join(File.join(DoiConfig.prefix.to_s, "DRI.#{datacite.object_id}-2"))
  end

  describe 'show' do
    before(:each) { @doi = DataciteDoi.create(object_id: @object.alternate_id) }
    after(:each) { @doi.delete }
    it 'should include a doi link' do
      expect(@doi.show['url']).to match(/https\:\/\/doi\.org\/10\.5072\/DRI\.(.+)/)
    end
    it 'should include a version number' do
      expect(@doi.show['version']).to be_a_kind_of(Numeric)
    end
    it 'should include the date it was created' do
      expect(@doi.show.keys.include?('created_at')).to be true
    end
  end
end
