require "spec_helper"

describe InstitutesController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user
  end

  describe "associate" do

    it "should associate an institute" do
      collection = FactoryGirl.create(:collection)
      institute = Institute.new
      institute.name = "Test Institute"
      institute.url = "http://www.test.ie"
      institute.save

      post :associate, object: collection.id, institute_name: institute.name

      collection.reload
      expect(collection.institute).to include(institute.name)
    end

    it "should associate a depositing institute" do
      collection = FactoryGirl.create(:collection)
      institute = Institute.new
      institute.name = "Test Institute"
      institute.url = "http://www.test.ie"
      institute.save

      post :associate, object: collection.id, institute_name: institute.name, type: "depositing"

      collection.reload
      expect(collection.depositing_institute).to eq(institute.name)
    end

  end

end
