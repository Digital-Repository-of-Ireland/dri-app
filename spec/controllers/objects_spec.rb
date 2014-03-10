require 'spec_helper'

describe ObjectsController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = Batch.new
    @collection[:title] = ["A collection"]
    @collection[:description] = ["This is a Collection"]
    @collection[:rights] = ["This is a statement about the rights associated with this object"]
    @collection[:publisher] = ["RnaG"]
    @collection[:type] = ["Collection"]
    @collection[:creation_date] = ["1916-01-01"]
    @collection[:published_date] = ["1916-04-01"]    
    @collection[:status] = ["draft"]
    @collection.save
    
    @object = Batch.new
    @object[:title] = ["An Audio Title"]
    @object[:rights] = ["This is a statement about the rights associated with this object"]
    @object[:role_hst] = ["Collins, Michael"]
    @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
    @object[:language] = ["ga"]
    @object[:description] = ["This is an Audio file"]
    @object[:published_date] = ["1916-04-01"]
    @object[:creation_date] = ["1916-01-01"]
    @object[:source] = ["CD nnn nuig"]
    @object[:geographical_coverage] = ["Dublin"]
    @object[:temporal_coverage] = ["1900s"]
    @object[:subject] = ["Ireland","something else"]
    @object[:type] = ["Sound"]
    @object[:status] = ["draft"]
    @object.save

    @collection.governed_items << @object    
    @collection.save
  end

  after(:each) do
    @object.delete
    @collection.delete
    @login_user.delete
  end

  describe 'status' do

    it 'should set a collection status' do
      DoiConfig = nil
      post :status, :id => @collection.id, :status => "published"

      @collection.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("draft")
    end

    it 'should set collection objects status' do
      DoiConfig = nil
      post :status, :id => @collection.id, :status => "published", :update_objects => "yes", :objects_status => "published"

      @collection.reload
      @object.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("published")
    end

    it 'should mint a doi if an object is published' do
      DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://www.dri.ie/repository", :publisher => "Digital Repository of Ireland" })

      Sufia.queue.should_receive(:push).with(an_instance_of(MintDoiJob)).twice
      post :status, :id => @collection.id, :status => "published", :update_objects => "yes", :objects_status => "published"

      @collection.reload
      @object.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("published")
    end

  end

end
