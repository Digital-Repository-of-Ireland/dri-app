require 'spec_helper'

describe SurrogatesController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
    @object = FactoryGirl.create(:sound)
    
    @collection.governed_items << @object    
    @collection.save
    
    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@login_user)
    @gf.batch = @object
    @gf.save
  end

  after(:each) do
    @gf.delete
    @object.delete
    @collection.delete

    @login_user.delete
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @collection.id
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, id: @object.id
    end

    it 'should update multiple files' do
      @gf2 = DRI::GenericFile.new
      @gf2.apply_depositor_metadata(@login_user)
      @gf2.batch = @object
      @gf2.save
      
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, id: @object.id

      @gf2.delete
    end

  end
end
