require 'spec_helper'

describe MetadataController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @object = FactoryGirl.create(:sound)
    @object[:status] = 'draft'
    @object.save  
  end

  after(:each) do
    @login_user.delete
    @object.delete
  end
  
  describe 'update' do

    it 'should update an object with a valid metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      put :update, id: @object.id, metadata_file: @file

      @object.reload
      expect(@object.title).to eq(['SAMPLE AUDIO TITLE'])
    end

    it 'should not update an object with an invalid metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/metadata_no_creator.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      put :update, id: @object.id, metadata_file: @file

      @object.reload
      expect(@object.title).to eq(['An Audio Title'])
    end

  end

end
