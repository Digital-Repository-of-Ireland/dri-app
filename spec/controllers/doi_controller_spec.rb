require 'spec_helper'

describe DoiController do
  include Devise::TestHelpers

  before(:all) do
    DoiConfig = OpenStruct.new({ :username => "user", :password => "password", :prefix => '10.5072', :base_url => "http://repository.dri.ie", :publisher => "Digital Repository of Ireland" })
  end

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user
  end

  describe "GET show" do
  
    it "should assign @history" do
      doi = DataciteDoi.create(object_id: "test")

      get :show, object_id: "test", id: doi
      expect(assigns(:history)).to eq([doi])      
    end

    it "should alert if doi is not the latest" do
      doi = DataciteDoi.create(object_id: "test")

      get :show, object_id: "test", id: "test"
      expect(flash[:notice]).to be_present
    end

  end

end
