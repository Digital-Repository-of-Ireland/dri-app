require 'rails_helper'
require 'solr/query'

RSpec.configure do |c|
  # declare an exclusion filter
  c.filter_run_excluding :slow => true
end

describe "Query" do

  before(:each) do
    @collection = FactoryGirl.create(:collection)
  end

  after(:each) do
    @collection.destroy
  end
  
  describe "run" do
    @slow
    it "should return results more than chunk size", :slow => true do
      20.times do
        o = FactoryGirl.create(:sound)
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
        o = FactoryGirl.create(:sound)
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
        o = FactoryGirl.create(:sound)
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
