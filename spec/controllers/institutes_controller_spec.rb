require "rails_helper"

describe InstitutesController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)
    @subcollection = FactoryBot.create(:collection)
    @institute = Institute.new
    @institute.name = "Test Institute"
    @institute.url = "http://www.test.ie"
    @institute.save
  end

  after(:each) do
    @collection.destroy
    @institute.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe "associate" do

    it "should associate an institute" do
      post :associate, params: { object: @collection.alternate_id, institute_name: @institute.name }

      @collection.reload
      expect(@collection.institute).to include(@institute.name)
    end

    it "should associate a depositing institute" do
      post :associate, params: { object: @collection.alternate_id, institute_name: @institute.name, type: "depositing" }

      @collection.reload
      expect(@collection.depositing_institute).to eq(@institute.name)
    end

    it "should create a new AIP when updating the institute_name" do
      expect(Dir.entries(aip_dir(@collection.alternate_id)).size - 2).to eq(1)
      expect(aip_valid?(@collection.alternate_id, 1)).to be true

      post :associate, params: { object: @collection.alternate_id, institute_name: @institute.name }

      expect(Dir.entries(aip_dir(@collection.alternate_id)).size - 2).to eq(2)
      expect(aip_valid?(@collection.alternate_id, 2)).to be true
    end
  end

  describe "disassociate" do

    it "should remove an association" do
      @collection.institute = @collection.institute.push(@institute.name)
      @collection.save

      delete :disassociate, params: { object: @collection.alternate_id, institute_name: @institute.name }

      @collection.reload
      expect(@collection.institute).to eq []
    end
  end

  describe "destroy" do
    it "should not delete an organisation with collections" do
      @collection.institute = @collection.institute.push(@institute.name)
      @collection.save

      delete :destroy, params: { id: @institute.id }

      expect { @institute.reload }.to_not raise_error
    end

    it "should delete an organisation without collections" do
      delete :destroy, params: { id: @institute.id }

      expect { @institute.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
