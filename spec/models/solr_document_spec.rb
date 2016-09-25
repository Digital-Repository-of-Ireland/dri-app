require "spec_helper"

describe SolrDocument do

  before(:each) do
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

    @dinstitute = Institute.new
    @dinstitute.name = "Depositing Test Institute"
    @dinstitute.url = "http://www.test.ie"
    @dinstitute.save
  
    @collection.institute = [@institute.name]
    @collection.depositing_institute = @dinstitute.name
    @collection.save
  end

  after(:each) do
    @collection.delete
    @institute.delete
    @dinstitute.delete
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
end
