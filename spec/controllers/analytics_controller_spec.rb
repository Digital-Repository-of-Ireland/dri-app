require "rails_helper"

describe AnalyticsController do
  include Devise::Test::ControllerHelpers

  before(:all) do
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end

  describe "index" do

    it "should display an error if user does not have correct permissions" do
      login_user = FactoryBot.create(:user)
      sign_in login_user

      get :index
      
      expect(flash[:error]).to be_present
    end

    it "should not display an error if user does have correct permissions" do
      login_user = FactoryBot.create(:collection_manager)
      sign_in login_user

      get :index
      
      expect(flash[:error]).to_not be_present
      expect(response.status).to eq 200
    end

  end

  describe "show" do

    it "should display an error if user does not have correct permissions" do
      login_user = FactoryBot.create(:user)
      sign_in login_user

      user = FactoryBot.create(:user)
      get :show, id: 'test'
      
      expect(flash[:error]).to be_present
    end

     it "should raise an exception for an unknown collection" do
      login_user = FactoryBot.create(:collection_manager)
      sign_in login_user

      get :show, id: 'test'
      
      expect(response.status).to eq 400
    end

    it "should not display an error if user does have correct permissions and collection exists" do
      login_user = FactoryBot.create(:collection_manager)
      sign_in login_user

      collection  = FactoryBot.create(:collection)
      get :show, id: collection.id
      
      expect(flash[:error]).to_not be_present
      expect(response.status).to eq 200
    end

  end
end