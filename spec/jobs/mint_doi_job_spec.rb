require 'rails_helper'
require 'doi/datacite'

describe "MintDoiJob" do

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
    it "should mint a doi for an object" do
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(DOI::Datacite).to receive(:mint).and_return(201)
      expect_any_instance_of(DOI::Datacite).to receive(:metadata).and_return(201)

      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
    end

    it "should set the status for an unprocessable doi" do
      allow_any_instance_of(DOI::Datacite).to receive(:metadata).and_return(422)
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(DOI::Datacite).not_to receive(:mint)
      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
      doi.reload
      expect(doi.status).to eq 'unprocessable'
    end

    it "should set the status for failed metadata" do
      allow_any_instance_of(DOI::Datacite).to receive(:metadata).and_return(404)
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(DOI::Datacite).not_to receive(:mint)
      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
      doi.reload
      expect(doi.status).to eq 'failed'
    end

    it "should set the status for a failed mint" do
      allow_any_instance_of(DOI::Datacite).to receive(:metadata).and_return(201)
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(DOI::Datacite).to receive(:mint).and_return(422)
      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
      doi.reload
      expect(doi.status).to eq 'error'
    end

    it "should set the status for a success" do
      allow_any_instance_of(DOI::Datacite).to receive(:metadata).and_return(201)
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(false)
      expect_any_instance_of(DOI::Datacite).to receive(:mint).and_return(201)
      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
      doi.reload
      expect(doi.status).to eq 'minted'
    end

    it "should set the status for a existing DOI" do
      allow_any_instance_of(DOI::Datacite).to receive(:doi_exists?).and_return(true)
      doi = DataciteDoi.create(object_id: @object.alternate_id)
      MintDoiJob.perform(doi.id)
      doi.reload
      expect(doi.status).to eq 'minted'
    end
  end
end
