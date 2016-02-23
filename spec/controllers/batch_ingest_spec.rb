require 'spec_helper'

describe BatchIngestController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
  end

  after(:each) do
    @login_user.delete
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