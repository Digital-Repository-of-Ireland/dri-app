require "spec_helper"

describe InstitutesController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
    @subcollection = FactoryGirl.create(:collection)
    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save
  end

  after(:each) do
    @collection.delete
    @institute.delete
  end

  describe "associate" do

    it "should associate an institute" do
      post :associate, object: @collection.id, institute_name: @institute.name

      @collection.reload
      expect(@collection.institute).to include(@institute.name)
    end

    it "should associate a depositing institute" do
      post :associate, object: @collection.id, institute_name: @institute.name, type: "depositing"

      @collection.reload
      expect(@collection.depositing_institute).to eq(@institute.name)
    end

    it "should associate depositing institute for sub-collections" do
      @collection.governed_items << @subcollection
      @collection.save

      post :associate, object: @collection.id, institute_name: @institute.name, type: "depositing"

      @collection.reload
      @subcollection.reload
      expect(@subcollection.depositing_institute).to eq(@collection.depositing_institute)
    end

  end

  describe "disassociate" do
  
    it "should remove an association" do
      @collection.institute = @collection.institute.push( @institute.name )
      @collection.save

      delete :disassociate, object: @collection.id, institute_name: @institute.name
      @collection.reload
      expect(@collection.institute).to eq []
    end

  end

end
