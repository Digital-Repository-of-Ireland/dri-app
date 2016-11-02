require "spec_helper"

describe Institute do

  before(:each) do
    @collection = FactoryGirl.create(:collection)
    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save
  end

  after(:each) do
    @collection.delete
    @institute.delete
  end

  it "should return the institutes for a collection" do
    @collection.institute = [@institute.name]
    @collection.save
      
    expect(Institute.find_collection_institutes(@collection.institute)).to include(@institute)
  end

  it "should return nil if no institutes set" do
    expect(Institute.find_collection_institutes(@collection.institute)).to be nil
  end
end
