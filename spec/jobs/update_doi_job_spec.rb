require 'rails_helper'
require 'doi/datacite'

describe "UpdateDoiJob" do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    stub_const('DoiConfig', OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository", :publisher => "Digital Repository of Ireland" }))
    Settings.doi.enable = true

    @collection = DRI::DigitalObject.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:creator] = 'test@dri.ie'
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
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

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @object.delete
    @collection.delete

    Settings.doi.enable = false
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "run" do
    it "should update a doi for an object" do
      allow_any_instance_of(Doi::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(Doi::Datacite).to receive(:metadata).and_return(201)

      doi = DataciteDoi.create(object_id: @object.alternate_id)
      UpdateDoiJob.perform(doi.id)
    end

    it "should handle update of doi with no resource type object" do
      allow_any_instance_of(Doi::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(RestClient::Resource).to receive(:put).and_return(OpenStruct.new(code: 201))

      doi = DataciteDoi.create(object_id: @object.alternate_id)
      metadata = doi.doi_metadata
      metadata.resource_type = nil
      metadata.save

      UpdateDoiJob.perform(doi.id)
    end
  end
end