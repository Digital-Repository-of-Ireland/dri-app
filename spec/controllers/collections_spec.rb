require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user
  end

  after(:each) do
    @login_user.delete
  end

  describe 'DELETE destroy' do

    it 'should delete a collection' do
      @collection = Batch.new
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
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
      @object.save

      @collection.governed_items << @object

      @collection.governed_items.length.should == 1

      Sufia.queue.should_receive(:push).with(an_instance_of(DeleteCollectionJob)).once
      delete :destroy, :id => @collection.id
    end

  end

  describe 'publish' do

    it 'should publish a collection' do
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
 
      DoiConfig = nil
      Sufia.queue.should_receive(:push).with(an_instance_of(PublishJob)).once
      post :publish, :id => @collection.id

      @collection.reload

      expect(@collection.status).to eql("published")
      expect(@object.status).to eql("draft")
    end    

  end

  describe 'ingest' do

    it 'should create a collection from a metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      @file = fixture_file_upload("/collection_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :ingest, :metadata_file => @file
      response.should be_success    
    end

  end

end
