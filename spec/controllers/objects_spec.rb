require 'spec_helper'

describe ObjectsController do
  include Devise::TestHelpers

  describe 'destroy' do
    
    before(:each) do
      @login_user = FactoryGirl.create(:admin)
      sign_in @login_user
    end

    after(:each) do
      @login_user.delete
    end

    it 'should delete a draft object' do
      @collection = FactoryGirl.create(:collection)
   
      @object = FactoryGirl.create(:sound) 
      @object[:status] = "draft"
      @object.save

      @collection.governed_items << @object

      expect {
        delete :destroy, :id => @object.id
      }.to change { ActiveFedora::Base.exists?(@object.id) }.from(true).to(false)

      @collection.reload
      @collection.delete
    end

    it 'should not delete a published object' do
      @collection = FactoryGirl.create(:collection)
   
      @object = FactoryGirl.create(:sound) 
      @object[:status] = "published"
      @object.save

      @collection.governed_items << @object

      delete :destroy, :id => @object.id

      expect(ActiveFedora::Base.exists?(@object.id)).to be true

      @collection.reload
      @collection.delete
    end

  end

  describe 'status' do

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
      @object.delete if ActiveFedora::Base.exists?(@object.id)
      @collection.delete if ActiveFedora::Base.exists?(@collection.id)
      @login_user.delete
    end

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

    it 'should mint a doi for an update of mandatory fields' do
      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.id)

      Sufia.queue.should_receive(:push).with(an_instance_of(MintDoiJob)).once
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @object.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @object.id).first.delete
    end

    it 'should not mint a doi for no update of mandatory fields' do
      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.id)

      Sufia.queue.should_not_receive(:push).with(an_instance_of(MintDoiJob))
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["An Audio Title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @object.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @object.id).first.delete
    end

  end

end
