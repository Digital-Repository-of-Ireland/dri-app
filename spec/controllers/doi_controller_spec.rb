require 'spec_helper'

describe DoiController do
  include Devise::TestHelpers

  before(:all) do
    DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://repository.dri.ie", :publisher => "Digital Repository of Ireland" })
    Settings.doi.enable = true
  end

  after(:all) do
    DoiConfig = nil
    Settings.doi.enable = false
  end

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @object = FactoryGirl.create(:sound)    
  end

  describe "GET show" do
  
    it "should assign @history" do
      doi = DataciteDoi.create(object_id: @object.id)

      get :show, object_id: @object.id, id: doi
      expect(assigns(:history)).to eq([doi])      
    end

    it "should alert if doi is not the latest" do
      doi = DataciteDoi.create(object_id: @object.id)

      get :show, object_id: @object.id, id: "test"
      expect(flash[:notice]).to be_present
    end

    it "should update doi" do
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
      DataciteDoi.create(object_id: @collection.id)

      Sufia.queue.should_receive(:push).with(an_instance_of(MintDoiJob)).once
      put :update, :object_id => @collection.id, :modified => "objects added"

      DataciteDoi.where(object_id: @collection.id).first.delete
      @collection.delete
    end

  end

end
