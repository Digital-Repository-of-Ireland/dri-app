require 'spec_helper'

describe SurrogatesController do
  include Devise::TestHelpers

  before do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
    @collection.status = ["draft"]
    
    @object = FactoryGirl.create(:sound)
    @object.status = ["draft"]

    @collection.governed_items << @object    
    @collection.save
    @object.save

    @gf = GenericFile.new
    @gf.batch = @object
    @gf.save
  end

  after do
    @gf.delete
    @object.delete
    @collection.delete
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, :id => @collection.id
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, :id => @object.id
    end

    it 'should update multiple files' do
      @gf2 = GenericFile.new
      @gf2.batch = @object
      @gf2.save
      
      request.env["HTTP_REFERER"] = "/"
      Sufia.queue.should_receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, :id => @object.id

      @gf2.delete
    end

  end

end
