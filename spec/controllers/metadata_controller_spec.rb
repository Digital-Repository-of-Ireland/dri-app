require 'rails_helper'

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
      @object.destroy

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

      put :update, params: { id: @object.alternate_id, metadata_file: @file }

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

      put :update, params: { id: @object.alternate_id, metadata_file: @file }

      @object.reload
      expect(@object.title).to eq(['An Audio Title'])
    end

    it 'should mint a doi for an update of mandatory fields' do
      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { :username => "user",
            :password => "password",
            :prefix => '10.5072',
            :base_url => "http://repository.dri.ie",
            :publisher => "Digital Repository of Ireland" }
            )
        )
      Settings.doi.enable = true

      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.alternate_id)

      expect(Resque).to receive(:enqueue).once
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect {
        put :update, params: { id: @object.alternate_id, metadata_file: @file }
      }.to change{ DataciteDoi.count }.by(1)

      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'should not mint a doi for no update of mandatory fields' do
      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { :username => "user",
            :password => "password",
            :prefix => '10.5072',
            :base_url => "http://repository.dri.ie",
            :publisher => "Digital Repository of Ireland" }
            )
        )
      Settings.doi.enable = true

      @object.creator = ["Gallagher, Damien"]
      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.alternate_id)

      expect(Resque).to receive(:enqueue)
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/no_doi_change_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect {
        put :update, params: { id: @object.alternate_id, metadata_file: @file }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'should rollback doi if an update of mandatory fields fails' do
      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { :username => "user",
            :password => "password",
            :prefix => '10.5072',
            :base_url => "http://repository.dri.ie",
            :publisher => "Digital Repository of Ireland" }
            )
        )
      Settings.doi.enable = true

      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.alternate_id)

      expect_any_instance_of(DRI::DigitalObject).to receive(:save).and_return(false)

      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect {
        put :update, params: { id: @object.alternate_id, metadata_file: @file }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

  end

  describe 'read only set' do

    before(:each) do
        Settings.add_source!(
                          file_fixture("settings-ro.yml").to_s
        )
  Settings.reload!
        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @login_user = FactoryBot.create(:admin)
        sign_in @login_user
        @object = FactoryBot.create(:sound)

        request.env["HTTP_REFERER"] = search_catalog_path
      end

      after(:each) do
        @object.delete if DRI::Identifier.object_exists?(@object.alternate_id)
        @login_user.delete

        Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
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

      put :update, params: { id: @object.alternate_id, metadata_file: @file }
      expect(response.status).to eq(503)
    end

  end

  describe 'show' do
    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:admin)
      sign_in @login_user

      @object = FactoryBot.create(:sound)
    end

    after(:each) do
      @object.destroy if DRI::Identifier.object_exists?(@object.alternate_id)
      @login_user.delete

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'renders the descMetadata datastream as xml' do
      get :show, params: { id: @object.alternate_id, format: :xml }

      expect(response).to be_successful
      expect(response.headers['Content-Disposition']).to include("#{@object.alternate_id}.xml")
    end

    it 'renders a js response with the metadata title and styled html' do
      # .js responses get Rails' built-in same-origin check (a legacy
      # protection against <script>-tag JSONP-style attacks); that's
      # framework behavior, not this controller's own logic, so we bypass
      # it here rather than trying to fabricate a Referer/Origin that
      # matches whatever host this test environment actually uses.
      allow_any_instance_of(MetadataController).to receive(:verify_same_origin_request)

      get :show, params: { id: @object.alternate_id, format: :js }

      expect(response).to be_successful
      expect(assigns(:display_xml)).to be_present
    end
  end

  describe 'show permissions' do
    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @collection = FactoryBot.create(:collection)
      @collection.status = 'published'
      @collection.save

      @object = FactoryBot.create(:sound)
      @object.discover_groups_string = 'public'
      @object.read_groups_string = 'public'
      @object.status = 'published'
      @object.save

      @collection.governed_items << @object
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'allows anonymous access to a public object (show requires no sign-in)' do
      get :show, params: { id: @object.alternate_id, format: :xml }

      expect(response).to be_successful
    end
  end

  describe 'update additional validations' do
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
      @object.destroy if DRI::Identifier.object_exists?(@object.alternate_id)

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'redirects with a notice when no metadata file or xml param is given' do
      put :update, params: { id: @object.alternate_id }

      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(controller: 'my_collections', action: 'show', id: @object.alternate_id)
    end

    it 'flashes an alert when persisting the update fails internally' do
      allow_any_instance_of(MetadataUpdateService).to receive(:call).and_raise(DRI::Exceptions::InternalError)

      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        attr_reader :tempfile
      end

      put :update, params: { id: @object.alternate_id, metadata_file: @file }

      expect(flash[:alert]).to be_present
    end

    it 'responds with plain text confirming the update' do
      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        attr_reader :tempfile
      end

      put :update, params: { id: @object.alternate_id, metadata_file: @file, format: :text }

      expect(response.body).to be_present
    end

    it 'redirects to the object for a plain html request' do
      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        attr_reader :tempfile
      end

      put :update, params: { id: @object.alternate_id, metadata_file: @file }

      expect(response).to redirect_to(controller: 'my_collections', action: 'show', id: @object.alternate_id)
    end
  end

  describe 'collection is locked' do
    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:admin)
      sign_in @login_user

      # Mirrors the proven pattern from ObjectsController's own
      # "collection is locked" spec: lock the *collection*, then attach
      # the object to it as its governing_collection - locking the
      # object's own alternate_id directly is not the right shape here.
      @collection = FactoryBot.create(:collection)
      CollectionLock.create(collection_id: @collection.alternate_id)

      @object = FactoryBot.create(:sound)
      @object.governing_collection = @collection
      @object.save

      request.env["HTTP_REFERER"] = search_catalog_path
    end

    after(:each) do
      CollectionLock.where(collection_id: @collection.alternate_id).delete_all
      @object.destroy if DRI::Identifier.object_exists?(@object.alternate_id)
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
      @login_user.delete

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'should not allow metadata updates' do
      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        attr_reader :tempfile
      end

      put :update, params: { id: @object.alternate_id, metadata_file: @file }

      expect(flash[:error]).to be_present
    end
  end

end