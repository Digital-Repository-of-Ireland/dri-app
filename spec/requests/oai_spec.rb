# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Oai requests", type: :request do
  let(:collection) { FactoryBot.create(:collection) }
  let(:object) { FactoryBot.create(:sound) }

  before do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    collection.status = "published"
    object.status = "published"
    object.save

    collection.governed_items << object
    collection.save
  end

  after do
    collection.destroy
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  it "renders the basic OAI response" do
    get "/oai?verb=Identify"
    expect(response).to be_successful
    expect(response.body).to match(%r{https:\/\/repository.dri.ie\/oai})
  end

  it "returns valid XML" do
    get "/oai"
    oai_xml = Nokogiri::XML(response.body)
    oai_xml.validate
    expect(oai_xml.errors).to eq([])
  end

  it "has dri as a metadata type" do
    get "/oai?verb=ListMetadataFormats"
    expect(response.body).to match(/oai_dri/)
  end

  it "has lists sets" do
    get "/oai?verb=ListSets"
    expect(response.body).to match(/collection:#{collection.alternate_id}/)
  end

  it "has a setSpec" do
    get "/oai", params: { verb: 'ListRecords', metadataPrefix: 'oai_dri' }
    expect(response.body).to match(%r{<setSpec>collection:#{collection.alternate_id}<\/setSpec>})
  end

  it "has a record in the repo" do
    get "/oai", params: { verb: 'ListRecords', metadataPrefix: 'oai_dri' }
    expect(response.body).to match(%r{<identifier>oai:dri:.*<\/identifier>})
  end

  it "has a record in the repo with a title" do
    get "/oai?verb=ListRecords&metadataPrefix=oai_dri"
    expect(response.body).to match(%r{<dc:title>.*<\/dc:title>})
  end

  it "has a Licence if one is added" do
    licence = Licence.create(name: "Test Licence", url: "http://test.com/licence")
    collection.licence = licence.name
    collection.save
    collection.reload

    get "/oai?verb=ListRecords&metadataPrefix=oai_dri"
    expect(response.body).to match(%r{<dcterms:license>http://test.com/licence<\/dcterms:license>})
  end

  it "has a Copyright if one is added" do
    copyright = Copyright.create(name: "Test Copyright", url: "http://test.com/copyright")
    collection.copyright = copyright.name
    collection.save
    collection.reload

    get "/oai?verb=ListRecords&metadataPrefix=oai_dri"
    expect(response.body).to match(%r{<dcterms:copyright>http://test.com/copyright<\/dcterms:copyright>})
  end

  it "has a dataProvider" do
    organisation = Institute.create(name: "Test Org", url: "http://test.org")
    collection.depositing_institute = organisation.name
    collection.save

    get "/oai?verb=ListRecords&metadataPrefix=oai_dri"
    expect(response.body).to match(%r{<edm:dataProvider>Test Org<\/edm:dataProvider>})
  end
end
