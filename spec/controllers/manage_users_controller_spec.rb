require "rails_helper"

describe ManageUsersController do
  include Devise::Test::ControllerHelpers

  before(:all) do
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_OM, description: "organisational manager test group")
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
    UserGroup::Group.find_by(name: SETTING_GROUP_OM).delete
  end

  describe "create" do
    it "should add a user to the collection manager group" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      user = FactoryBot.create(:user)

      post :create, params: { user: user.email }

      expect(user.groups.pluck(:name)).to include('cm')
    end

    it "should add a user to the organisational manager group" do
      login_user = FactoryBot.create(:admin)
      sign_in login_user

      user = FactoryBot.create(:user)

      post :create, params: { user: user.email, type: 'om' }

      expect(user.groups.pluck(:name)).to include('cm')
      expect(user.groups.pluck(:name)).to include('om')
    end

    it "should display an error if the user is not found" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      post :create, params: { user: 'test' }

      expect(flash[:error]).to be_present
    end

    it "should display an error if user does not have correct permissions" do
      login_user = FactoryBot.create(:collection_manager)
      sign_in login_user

      user = FactoryBot.create(:user)
      post :create, params: { user: user.email }
      expect(response).to have_http_status(401)
    end
  end
  
  describe "show" do    
    it "should raise an error if the user is not a cm" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      user = FactoryBot.create(:user)
      get :show, params: { user_id: user.id }
      expect(response).to have_http_status(400)
    end

    it "should raise an error if the user was not approved by the manager" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      user = FactoryBot.create(:collection_manager)
      get :show, params: { user_id: user.id }
      expect(response).to have_http_status(400)
    end

    it "should allow org manager to see their collection managers" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      user = FactoryBot.create(:collection_manager)
      m = user.memberships.find_by(group_id: UserGroup::Group.find_by(name: 'cm'))
      m.approved_by = login_user.id
      m.save

      get :show, params: { user_id: user.id }
      expect(response).to have_http_status(200)
    end
  end

  describe "destroy" do
    it "should remove a user to the collection manager group" do
      login_user = FactoryBot.create(:organisation_manager)
      sign_in login_user

      user = FactoryBot.create(:collection_manager)

      delete :destroy, params: { user_id: user.id }

      expect(user.groups.pluck(:name)).to_not include('cm')
    end
  end
end
