require "rails_helper"

describe CollectionConfigsController do
  include Devise::Test::ControllerHelpers

  describe 'GET show' do
    let(:collection) { FactoryBot.create(:collection) }
    let(:login_user) { FactoryBot.create(:collection_manager) }

    before(:each) do
      sign_in login_user
    end
  
    it "should create the config on show" do
      expect {
        get :show, params: { collection_id: collection.alternate_id }
      }.to change{ CollectionConfig.count }.by(1)
    end
  end

  describe 'PUT update' do
    let(:collection) { FactoryBot.create(:collection) }
    let(:login_user) { FactoryBot.create(:collection_manager) }

    before(:each) do
      sign_in login_user
    end
  
    it "should create the config on show" do
      config = CollectionConfig.create(collection_id: collection.alternate_id, allow_export: false)
      expect(CollectionConfig.can_export?(collection.alternate_id)).to be false
      put :update, params: { collection_id: collection.alternate_id, collection_config: { allow_export: true } }
      config.reload
      expect(CollectionConfig.can_export?(collection.alternate_id)).to be true
    end
  end
end