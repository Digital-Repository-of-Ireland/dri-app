require 'rails_helper'

describe BatchIngestController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
    
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
  end

  after(:each) do
    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'CREATE' do

    it 'should return accepted for valid json' do
      json = { id: @collection.id, :format => 'json', :batch_ingest => { :name => "foo", :description => "bar" }.to_json }
      Resque.should_receive(:enqueue).once
      post :create, json
      response.status.should eq(202)
    end

    it 'should return bad request for invalid json' do
      json = { id: @collection.id, :format => 'json', :batch_ingest => "{ \"name\": \"foo\", \"description\": [\"bar\" }" }
      expect(Resque).to_not receive(:enqueue)
      post :create, json
      response.status.should eq(400)
    end

  end
end