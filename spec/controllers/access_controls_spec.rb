require 'rails_helper'
require 'shared_contexts'

describe AccessControlsController, type: :request do
  #include Devise::Test::ControllerHelpers
  include_context "api request authentication helper methods"
  include_context "api request global before and after hooks"

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

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
    @collection.destroy
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should update valid permissions' do
      put "/objects/#{@collection.noid}/access", digital_object: { read_groups_string: @collection.noid.to_s, manager_users_string: @login_user.to_s }
      @collection.reload

      expect(@collection.read_groups_string).to eq(@collection.noid.to_s)
    end

    it 'should not update with invalid permissions' do
      put "/objects/#{@collection.noid}/access", digital_object: { edit_users_string: '', manager_users_string: '' }
      @collection.reload

      expect(@collection.manager_users_string).to eq(@login_user.to_s)
      expect(controller).to set_flash[:alert]
    end

  end
end
