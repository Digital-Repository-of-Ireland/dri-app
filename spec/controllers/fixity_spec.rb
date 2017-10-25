require 'rails_helper'
require 'securerandom'

describe FixityController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
    @object = FactoryGirl.create(:sound)
    
    @collection.governed_items << @object    
    @collection.save    
  end

  after(:each) do
    @collection.delete

    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should trigger a fixity check for an object' do
      request.env["HTTP_REFERER"] = "/"
      expect{ put :update, id: @object.id }.to change(FixityCheck, :count).by(1)
    end

  end
end
