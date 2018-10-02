describe MetadataController do
  include Devise::Test::ControllerHelpers
    
  describe 'update' do

    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:admin)
      sign_in @login_user

      @object = FactoryBot.create(:sound)
      @object[:status] = 'draft'
      @object.save  
    end

    after(:each) do
      @login_user.delete
      @object.delete

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

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

  describe 'read only set' do

    before(:each) do
        Settings.reload_from_files(
          Rails.root.join(fixture_path, "settings-ro.yml").to_s
        )
        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @login_user = FactoryBot.create(:admin)
        sign_in @login_user
        @object = FactoryBot.create(:sound) 

        request.env["HTTP_REFERER"] = catalog_index_path
      end

      after(:each) do
        @object.delete if ActiveFedora::Base.exists?(@object.id)
        @login_user.delete

        Settings.reload_from_files(
          Rails.root.join("config", "settings.yml").to_s
        )

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
      end

    it 'should not update an object' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      put :update, id: @object.id, metadata_file: @file
      expect(response.status).to eq(503)
    end

  end

end
