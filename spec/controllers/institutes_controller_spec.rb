require "rails_helper"

describe InstitutesController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

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
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
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
   
    it "should create a new AIP when updating the institute_name" do
      expect(Dir.entries(aip_dir(@collection.id)).size - 2).to eq(1)
      expect(aip_valid?(@collection.id, 1)).to be true
      
      post :associate, object: @collection.id, institute_name: @institute.name

      expect(Dir.entries(aip_dir(@collection.id)).size - 2).to eq(2)
      expect(aip_valid?(@collection.id, 2)).to be true
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
