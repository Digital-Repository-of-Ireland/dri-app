require 'spec_helper'

describe AccessControlsController, :type => :request do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
    @collection.apply_depositor_metadata(@login_user.to_s)
    @collection.manager_users_string = @login_user.to_s
    @collection.discover_groups_string = 'public'
    @collection.read_groups_string = 'public'
    @collection.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete
  end

  describe 'update' do

    it 'should update valid permissions' do
      put :update, id: @collection.id, batch: { read_groups_string: @collection.id.to_s, manager_users_string: @login_user.to_s }
      @collection.reload

      expect(@collection.read_groups_string).to eq(@collection.id.to_s)
    end

    it 'should not update with invalid permissions' do
      put :update, id: @collection.id, batch: { edit_users_string: '', manager_users_string: '' }
      @collection.reload

      expect(@collection.manager_users_string).to eq(@login_user.to_s)
      expect(controller).to set_flash[:alert]
    end

  end
end
