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
      json = { id: @collection.noid, format: 'json', batch_ingest: { name: "foo", description: "bar" }.to_json }
      expect(Resque).to receive(:enqueue).once
      post :create, json
      expect(response.status).to eq(202)
    end

    it 'should return bad request for invalid json' do
      json = { id: @collection.noid, format: 'json', batch_ingest: "{ \"name\": \"foo\", \"description\": [\"bar\" }" }
      expect(Resque).to_not receive(:enqueue)
      post :create, json
      expect(response.status).to eq(400)
    end

  end
end