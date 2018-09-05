require 'doi/datacite'

describe "MintDoiJob" do

  before(:each) do
    stub_const('DoiConfig', OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository", :publisher => "Digital Repository of Ireland" }))
    Settings.doi.enable = true

    @collection = DRI::Batch.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:resource_type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection[:status] = "draft"
    @collection.save

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
  end
  
  describe "run" do
    it "should mint a doi for an object" do
      expect_any_instance_of(DOI::Datacite).to receive(:mint)
      expect_any_instance_of(DOI::Datacite).to receive(:metadata)
      
      DataciteDoi.create(object_id: @object.id)
      
      job = MintDoiJob.new(@object.id)
      job.run

      @object.reload

      expect(@object.doi).to eql("10.5072/DRI.#{@object.id}")     
    end

  end
end
