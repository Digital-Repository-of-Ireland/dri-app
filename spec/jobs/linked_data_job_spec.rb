require 'rails_helper'

describe LinkedDataJob do

  before(:each) do
    stub_const('AuthoritiesConfig', OpenStruct.new(
      { :'data.logainm.ie' =>
        { 'provider' => 'Logainm',
          'endpoint' => 'http://data.logainm.ie/sparql'
        }
      }))

    @collection = FactoryBot.create(:collection)

    @object = FactoryBot.create(:sound)
    @object[:geographical_coverage] = ["http://data.logainm.ie/place/114000"]
    @object.save

    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @collection.delete
  end

  describe "run" do
    it "should try to process a URI" do
      expect_any_instance_of(DRI::Sparql::Provider::Logainm).to receive(:retrieve_data)

      job = LinkedDataJob.new(@object.id)
      job.run
    end

    it "should handle trailing whitespace" do
      @object[:geographical_coverage] = ["http://data.logainm.ie/place/114000 "]
      @object.save

      expect_any_instance_of(DRI::Sparql::Provider::Logainm).to receive(:retrieve_data)

      job = LinkedDataJob.new(@object.id)
      job.run
    end
  end
end
