require "rails_helper"

describe SolrDocument do

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryGirl.create(:collection)
    @subcollection = FactoryGirl.create(:collection)
    @object = FactoryGirl.create(:sound)

    @subcollection.governing_collection = @collection
    @subcollection.governed_items << @object
    @subcollection.save

    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save

    @institute_b = Institute.new
    @institute_b.name = "Second Test Institute"
    @institute_b.url = "http://www.secondtest.ie"
    @institute_b.save

    @dinstitute = Institute.new
    @dinstitute.name = "Depositing Test Institute"
    @dinstitute.url = "http://www.test.ie"
    @dinstitute.save
  
    @collection.institute = [@institute.name, @institute_b.name]
    @collection.depositing_institute = @dinstitute.name
    @collection.save
  end

  after(:each) do
    @collection.delete
    @institute.delete
    @dinstitute.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  context "when retrieving the depositing institute" do
    it "returns collection institute" do
      doc = SolrDocument.new(@collection.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end

    it "returns inherited collection institute" do
      doc = SolrDocument.new(@subcollection.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end

    it "returns collection institute for object" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.depositing_institute).to eq @dinstitute
    end
  end

  context "when returning institutes" do
    it "returns all a collections institutes" do
      doc = SolrDocument.new(@collection.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end

    it "returns inherited collection institutes" do
      doc = SolrDocument.new(@subcollection.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end

    it "returns collection institutes for object" do
      doc = SolrDocument.new(@object.to_solr)
      expect(doc.institutes).to match_array([@institute, @institute_b])
    end
  end
end
