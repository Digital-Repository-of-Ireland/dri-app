require 'rails_helper'

describe AccessControlsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)
    @object = FactoryBot.create(:sound)
    @object.governing_collection = @collection
    @object.save
    @collection.governed_items << @object
    @collection.save
  end

  after(:each) do
    @object.destroy if DRI::Identifier.object_exists?(@object.alternate_id)
    @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    @login_user.delete

    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'edit' do
    it 'renders successfully for an object' do
      allow_any_instance_of(AccessControlsController).to receive(:verify_same_origin_request)

      get :edit, params: { id: @object.alternate_id, format: :js }

      expect(response).to be_successful
    end

    it 'renders successfully for a collection' do
      allow_any_instance_of(AccessControlsController).to receive(:verify_same_origin_request)

      get :edit, params: { id: @collection.alternate_id, format: :js }

      expect(response).to be_successful
    end

    it 'denies a signed-in user without edit/manage permissions' do
      allow_any_instance_of(AccessControlsController).to receive(:verify_same_origin_request)

      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      get :edit, params: { id: @object.alternate_id, format: :js }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end
  end

  describe 'update' do
    it 'updates access controls successfully' do
      expect(Resque).to receive(:enqueue).with(VisibilityJob, @object.alternate_id)

      put :update, params: {
        id: @object.alternate_id,
        digital_object: {
          read_groups_string: 'public',
          read_users_string: '',
          edit_users_string: @login_user.email,
          master_file_access: 'public'
        }
      }

      expect(flash[:notice]).to be_present
    end

    it 'denies a signed-in user without edit/manage permissions' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      put :update, params: {
        id: @object.alternate_id,
        digital_object: { read_groups_string: 'public', edit_users_string: @plain_user.email }
      }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end

    it 'blocks updates when the app is in read-only mode' do
      Settings.add_source!(file_fixture("settings-ro.yml").to_s)
      Settings.reload!

      put :update, params: {
        id: @object.alternate_id,
        digital_object: { read_groups_string: 'public', edit_users_string: @login_user.email }
      }

      expect(flash[:error]).to be_present

      Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
    end

    it 'blocks updates on an object governed by a locked collection' do
      CollectionLock.create(collection_id: @collection.alternate_id)

      put :update, params: {
        id: @object.alternate_id,
        digital_object: { read_groups_string: 'public', edit_users_string: @login_user.email }
      }

      expect(flash[:error]).to be_present

      CollectionLock.where(collection_id: @collection.alternate_id).delete_all
    end

    it 'does not update a root-level collection when no manager/editor permissions are given' do
      put :update, params: {
        id: @collection.alternate_id,
        digital_object: { read_groups_string: 'public' }
      }

      expect(flash[:alert]).to be_present
    end

    it 'does update a root-level collection when a manager is being set' do
      put :update, params: {
        id: @collection.alternate_id,
        digital_object: { read_groups_string: 'public', manager_users_string: @login_user.email }
      }

      expect(flash[:notice]).to be_present
    end
  end

  describe 'show' do
    it 'denies a non-manager' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      get :show, params: { id: @collection.alternate_id }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end

    it 'builds the access controls tree for html requests' do
      get :show, params: { id: @collection.alternate_id }

      expect(response).to be_successful
      expect(assigns(:access_controls)).to be_present
    end

    it 'returns a csv report for csv requests' do
      get :show, params: { id: @collection.alternate_id, format: :csv }

      expect(response).to be_successful
      expect(response.headers['Content-Type']).to include('text/csv')
    end
  end
end