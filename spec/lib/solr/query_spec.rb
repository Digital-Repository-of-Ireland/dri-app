require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "Query" do

  before(:each) do
    @collection = DRI::Batch.with_standard :qdc
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]
    @collection[:status] = "draft"
    @collection.save
  end

  after(:each) do
    @collection.delete
  end
  
  describe "run" do
    @slow
    it "should return results more than chunk size", :slow => true do
      20.times do
        o = FactoryBot.create(:sound)
        o.save

        @collection.governed_items << o
      end

      @collection.save

      query = Solr::Query.new("collection_id_sim:\"#{@collection.id}\"", 10)
      count = 0      
      while query.has_more?
        count += query.pop.count
      end
 
      count.should eq(20)
    end

    @slow
    it "should return results equal to the chunk size", :slow => true do
      10.times do
        o = FactoryBot.create(:sound)
        o.save

        @collection.governed_items << o
      end

      @collection.save

      query = Solr::Query.new("collection_id_sim:\"#{@collection.id}\"", 10)
      count = 0
      while query.has_more?
        count += query.pop.count
      end

      count.should eq(10)
    end

    @slow
    it "should handle results between chunk sizes", :slow => true do
      27.times do
        o = FactoryBot.create(:sound)
        o.save

        @collection.governed_items << o
      end

      @collection.save

      query = Solr::Query.new("collection_id_sim:\"#{@collection.id}\"", 10)
      count = 0
      while query.has_more?
        count += query.pop.count
      end

      count.should eq(27)
    end

  end
 
end
