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
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection.save
      
      @object = DRI::Batch.with_standard :qdc
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

      @collection.governed_items.size.should == 1

      Sufia.queue.should_receive(:push).with(an_instance_of(DeleteCollectionJob)).once
      delete :destroy, :id => @collection.id
    end

  end

  describe 'publish' do

    it 'should publish a collection' do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      @object = DRI::Batch.with_standard :qdc
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
      @object[:status] = "draft"
      @object.save

      @collection.governed_items << @object
 
      DoiConfig = nil
      Sufia.queue.should_receive(:push).with(an_instance_of(PublishJob)).once
      post :publish, :id => @collection.id
    end    

  end

  describe 'update' do
    
    it 'should allow a subcollection to be updated' do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      @subcollection = DRI::Batch.with_standard :qdc
      @subcollection[:title] = ["A sub collection"]
      @subcollection[:description] = ["This is a sub-collection"]
      @subcollection[:creator] = [@login_user.email]
      @subcollection[:rights] = ["This is a statement about the rights associated with this object"]
      @subcollection[:publisher] = ["RnaG"]
      @subcollection[:type] = ["Collection"]
      @subcollection[:creation_date] = ["1916-01-01"]
      @subcollection[:published_date] = ["1916-04-01"]
      @subcollection[:status] = "draft"
      @subcollection.save

      @collection.governed_items << @subcollection
      @collection.reload
      @subcollection.reload
 
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified sub collection title"]
      put :update, :id => @subcollection.id, :batch => params[:batch]
      expect(@subcollection.title).to eq(["A modified sub collection title"])
      #expect(page.find('.dri_alert_text')).to have_content I18n.t('dri.flash.notice.updated', item: @subcollection.id)

      @collection.delete
    end

    it 'should mint a doi for an update of mandatory fields' do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "published"
      @collection.save

      DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://repository.dri.ie", :publisher => "Digital Repository of Ireland" })
      Settings.doi.enable = true

      DataciteDoi.create(object_id: @collection.id)

      Sufia.queue.should_receive(:push).with(an_instance_of(MintDoiJob)).once
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @collection.id).first.delete
      DoiConfig = nil
      Settings.doi.enable = false
    end

    it 'should not mint a doi for no update of mandatory fields' do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "published"
      @collection.save

      DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://repository.dri.ie", :publisher => "Digital Repository of Ireland" })
      Settings.doi.enable = true

      DataciteDoi.create(object_id: @collection.id)

      Sufia.queue.should_not_receive(:push).with(an_instance_of(MintDoiJob))
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A collection"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @collection.id).first.delete
      DoiConfig = nil
      Settings.doi.enable = false
    end

  end

  describe 'ingest' do

    it 'should create a collection from a metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/collection_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, :metadata_file => @file
      response.should be_success    
    end

  end

end
