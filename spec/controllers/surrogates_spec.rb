require 'rails_helper'

describe SurrogatesController do
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
    
    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@login_user)
    @gf.digital_object = @object
    @gf.save
  end

  after(:each) do
    @collection.destroy
    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @collection.noid
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @object.noid
    end

    it 'should update multiple files' do
      @gf2 = DRI::GenericFile.new
      @gf2.apply_depositor_metadata(@login_user)
      @gf2.digital_object = @object
      @gf2.save
      
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, id: @object.noid

      @gf2.destroy
    end

  end
end
