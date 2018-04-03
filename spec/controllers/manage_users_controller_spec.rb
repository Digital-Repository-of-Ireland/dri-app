require "rails_helper"

describe ManageUsersController do
  include Devise::Test::ControllerHelpers

  before(:all) do
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end

  describe "create" do

    it "should add a user to the collection manager group" do
      login_user = FactoryBot.create(:admin)
      sign_in login_user
 
      user = FactoryBot.create(:user)

      post :create, user: user.email

      expect(user.groups.pluck(:name)).to include('cm')
    end

    it "should display an error if the user is not found" do
      login_user = FactoryBot.create(:admin)
      sign_in login_user

      post :create, user: 'test'

      expect(flash[:error]).to be_present
    end

    it "should display an error if user does not have correct permissions" do
      login_user = FactoryBot.create(:collection_manager)
      sign_in login_user

      user = FactoryBot.create(:user)
      post :create, user: user.email
      
      expect(flash[:error]).to be_present
    end

  end
end
