require 'spec_helper'

describe ObjectsController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
   
    @object = FactoryGirl.create(:sound) 
    @object[:status] = "draft"
    @object.save

    @object2 = FactoryGirl.create(:sound)
    @object2[:status] = "draft"
    @object2.save

    @collection.governed_items << @object
    @collection.governed_items << @object2

    @collection.save    
  end

  after(:each) do
    @object2.delete
    @object.delete
    @collection.delete
    @login_user.delete
  end

  describe 'status' do

    it 'should set an object status' do
      post :status, :id => @object.id, :status => "reviewed"

      @object.reload

      expect(@object.status).to eql("reviewed")

      post :status, :id => @object.id, :status => "draft"

      @object.reload

      expect(@object.status).to eql("draft")
    end

    it 'should not set the status of a published object' do
      @object.status = "published"
      @object.save

      post :status, :id => @object.id, :status => "draft"

      @object.reload

      expect(@object.status).to eql("published") 
    end

    it 'should set the status of all objects in collection' do
      Sufia.queue.should_receive(:push).with(an_instance_of(ReviewJob)).once
      post :status, :id => @object.id, :status => "reviewed", :apply_all => "yes"

      @object.reload

      expect(@object.status).to eql("reviewed")
    end

  end

end
