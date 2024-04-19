require 'rails_helper'

describe ExportsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'create' do

    before(:each) do
      @login_user = FactoryBot.create(:user)
      sign_in @login_user
    end

    after(:each) do
      @login_user.delete
    end

    it 'should start an export if config allows' do
      @collection = FactoryBot.create(:collection)
      CollectionConfig.create(collection_id: @collection.alternate_id, allow_export: true)
      @request.env['HTTP_REFERER'] = "/collections/#{@collection.id}/export/new"

      expect(Resque).to receive(:enqueue).once
      post :create, params: { id: @collection.alternate_id }
    end

     it 'should not start an export if config does not allow' do
      @collection = FactoryBot.create(:collection)
      CollectionConfig.create(collection_id: @collection.alternate_id, allow_export: false)
      @request.env['HTTP_REFERER'] = "/collections/#{@collection.id}/export/new"

      expect(Resque).to_not receive(:enqueue)
      post :create, params: { id: @collection.alternate_id }
    end

    it 'should start an export if user can edit' do
      @collection = FactoryBot.create(:collection)
      @collection.edit_users_string=User.find_by_email(@login_user.email).to_s
      @collection.save
      CollectionConfig.create(collection_id: @collection.alternate_id, allow_export: false)
      @request.env['HTTP_REFERER'] = "/collections/#{@collection.id}/export/new"

      expect(Resque).to receive(:enqueue)
      post :create, params: { id: @collection.alternate_id }
    end
  end
end
