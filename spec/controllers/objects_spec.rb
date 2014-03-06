require 'spec_helper'

describe ObjectsController do
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
  end

  after do
    @object.delete
    @collection.delete
  end

  describe 'status' do

    it 'should set a collection status' do
      post :status, :id => @collection.id, :status => "published"

      @collection.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("draft")
    end

    it 'should set collection objects status' do
      post :status, :id => @collection.id, :status => "published", :update_objects => "yes", :objects_status => "published"

      @collection.reload
      @object.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("published")
    end

  end

end
