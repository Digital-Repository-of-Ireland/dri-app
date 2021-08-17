require 'rails_helper'

describe ObjectsController do
  include Devise::Test::ControllerHelpers
  include Warden::Test::Helpers
  include Preservation::PreservationHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'destroy' do

    before(:each) do
      @login_user = FactoryBot.create(:collection_manager)
      sign_in @login_user
    end

    after(:each) do
      @login_user.delete
    end

    it 'should delete a draft object' do
      collection = FactoryBot.create(:collection)
      collection.depositor = User.find_by_email(@login_user.email).to_s
      collection.manager_users_string=User.find_by_email(@login_user.email).to_s
      collection.discover_groups_string="public"
      collection.read_groups_string="registered"
      collection.creator = [@login_user.email]

      object = FactoryBot.create(:sound)
      object[:status] = "draft"
      object.depositor=User.find_by_email(@login_user.email).to_s
      object.manager_users_string=User.find_by_email(@login_user.email).to_s
      object.creator = [@login_user.email]

      object.save

      collection.governed_items << object

      expect {
        delete :destroy, params: { id: object.alternate_id }
      }.to change { DRI::Identifier.object_exists?(object.alternate_id) }.from(true).to(false)

      collection.reload
      collection.destroy
    end

    it 'should not delete a published object for non-admin' do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = User.find_by_email(@login_user.email).to_s
      @collection.manager_users_string=User.find_by_email(@login_user.email).to_s
      @collection.discover_groups_string="public"
      @collection.read_groups_string="registered"
      @collection.creator = [@login_user.email]

      @object = FactoryBot.create(:sound)
      @object[:status] = "published"
      @object.save

      @collection.governed_items << @object

      delete :destroy, params: { id: @object.alternate_id }

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be true

      @collection.reload
      @collection.destroy
    end

    it 'should delete a published object for an admin' do
      sign_out @login_user
      @admin_user = FactoryBot.create(:admin)
      sign_in @admin_user

      @collection = FactoryBot.create(:collection)

      @object = FactoryBot.create(:sound)
      @object[:status] = "published"
      @object.save

      @collection.governed_items << @object

      delete :destroy,  params: { id: @object.alternate_id }

      expect(DRI::Identifier.object_exists?(@object.alternate_id)).to be false

      @collection.reload
      @collection.destroy
    end
  end

  describe 'create' do

    before(:each) do
      @login_user = FactoryBot.create(:admin)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection)
      @login_user.delete
    end

    it 'returns a bad request if no schema' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/invalid_metadata_noschema.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { digital_object: { governing_collection: @collection.alternate_id }, metadata_file: @file }

      expect(flash[:error]).to match(/Validation Errors/)
      expect(response.status).to eq(400)
    end

    it 'returns a bad request if schema invalid' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/invalid_metadata_schemaparse.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { digital_object: { governing_collection: @collection.alternate_id }, metadata_file: @file }

      expect(flash[:error]).to match(/Validation Errors/)
      expect(response.status).to eq(400)
    end

    it 'rollback an object save if indexing fails' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      expect_any_instance_of(DRI::DigitalObject)
        .to receive(:update_index).and_return(false)
      expect {
        post :create, params: { digital_object: { governing_collection: @collection.alternate_id }, metadata_file: @file }
      }.to change{ DRI::DigitalObject.count }.by(0)
    end
  end

  describe 'update' do
    before(:each) do
      @login_user = FactoryBot.create(:collection_manager)
      sign_in @login_user
    end

    after(:each) do
      @login_user.delete
    end

    it 'should rollback changes when an update fails' do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string=@login_user.email
      @collection.discover_groups_string="public"
      @collection.read_groups_string="registered"
      @collection.creator = [@login_user.email]

      @object = FactoryBot.create(:sound)
      @collection.governed_items << @object
      @collection.save

      title = @object.title

      expect_any_instance_of(DRI::DigitalObject)
        .to receive(:update_index).and_return(false)
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email

      put :update, params: { id: @object.alternate_id, digital_object: params[:digital_object] }

      @object.reload
      expect(@object.title).to eq(title)
      @collection.destroy
    end
  end

  describe 'status' do

    before(:each) do
      @login_user = FactoryBot.create(:collection_manager)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string=@login_user.email
      @collection.discover_groups_string="public"
      @collection.read_groups_string="registered"
      @collection.creator = [@login_user.email]

      @subcollection = FactoryBot.create(:collection)
      @subcollection.depositor = @login_user.email
      @subcollection.manager_users_string=@login_user.email
      @subcollection.discover_groups_string="public"
      @subcollection.read_groups_string="registered"
      @subcollection.creator = [@login_user.email]
      @subcollection.status = 'draft'

      @subsubcollection = FactoryBot.create(:collection)
      @subsubcollection.depositor = @login_user.email
      @subsubcollection.manager_users_string=@login_user.email
      @subsubcollection.discover_groups_string="public"
      @subsubcollection.read_groups_string="registered"
      @subsubcollection.creator = [@login_user.email]
      @subsubcollection.status = 'draft'

      @subcollection.governed_items << @subsubcollection
      @collection.governed_items << @subcollection

      @object = FactoryBot.create(:sound)
      @object[:status] = "draft"
      @object.save

      @object2 = FactoryBot.create(:sound)
      @object2[:status] = "draft"
      @object2.save

      @object3 = FactoryBot.create(:sound)
      @object3[:status] = "draft"
      @object3.save

      @object4 = FactoryBot.create(:sound)
      @object4[:status] = "draft"
      @object4.save

      @subsubcollection.governed_items << @object4
      @subsubcollection.save

      @subcollection.governed_items << @object3
      @subcollection.save

      @collection.governed_items << @object
      @collection.governed_items << @object2

      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
      @login_user.delete
    end

    it 'should set an object status' do
      post :status, params: { id: @object.alternate_id, status: "reviewed" }
      @object.reload

      expect(@object.status).to eql("reviewed")

      post :status, params: { id: @object.alternate_id, status: "draft" }

      @object.reload

      expect(@object.status).to eql("draft")
    end

    it 'should set a parent subcollection to reviewed' do
      post :status, params: { id: @object4.alternate_id, status: "reviewed" }

      @object4.reload
      expect(@object4.status).to eql("reviewed")

      @object3.reload
      expect(@object3.status).to eql("draft")

      @subsubcollection.reload
      expect(@subsubcollection.status).to eql("reviewed")

      @subcollection.reload
      expect(@subcollection.status).to eql("reviewed")

      @collection.reload
      expect(@collection.status).to eql("draft")
    end

    it 'should not set the status of a published object' do
      @object.status = "published"
      @object.save

      post :status, params: { id: @object.alternate_id, status: "draft" }
      @object.reload

      expect(@object.status).to eql("published")
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
      doi = DataciteDoi.create(object_id: @object.alternate_id)

      expect(Resque).to receive(:enqueue).once
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      expect {
        put :update, params: { id: @object.alternate_id, digital_object: params[:digital_object] }
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

      @object.status = "published"
      @object.save
      doi = DataciteDoi.create(object_id: @object.alternate_id)

      expect(Resque).to_not receive(:enqueue)
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["An Audio Title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      expect {
        put :update, params: { id: @object.alternate_id, digital_object: params[:digital_object] }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'should rollback DOI changes when an update fails' do
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
      doi = DataciteDoi.create(object_id: @object.alternate_id)

      expect_any_instance_of(DRI::DigitalObject)
        .to receive(:save).and_return(false)
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      expect {
        put :update, params: { id: @object.alternate_id, digital_object: params[:digital_object] }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

  end

  describe "read only is set" do

      before(:each) do
        Settings.add_source!(Rails.root.join(fixture_path, "settings-ro.yml").to_s)
	      Settings.reload!

        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @login_user = FactoryBot.create(:admin)
        sign_in @login_user
        @collection = FactoryBot.create(:collection)
        @object = FactoryBot.create(:sound)

        request.env["HTTP_REFERER"] = my_collections_path(@collection.id)
      end

      after(:each) do
        @collection.destroy if DRI::Identifier.object_exists?(@collection.id)
        @login_user.delete

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
      end

      it 'should not allow object creation' do
        @request.env["CONTENT_TYPE"] = "multipart/form-data"

        @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
        class << @file
          # The reader method is present in a real invocation,
          # but missing from the fixture object for some reason (Rails 3.1.1)
          attr_reader :tempfile
        end

        post :create, params: { digital_object: { governing_collection: @collection.alternate_id }, metadata_file: @file }

        expect(flash[:error]).to be_present
      end

      it 'should not allow object updates' do
        params = {}
        params[:digital_object] = {}
        params[:digital_object][:title] = ["An Audio Title"]
        params[:digital_object][:read_users_string] = "public"
        params[:digital_object][:edit_users_string] = @login_user.email
        put :update, params: { :id => @object.alternate_id, :digital_object => params[:digital_object] }

        expect(flash[:error]).to be_present
      end

  end

  describe "collection is locked" do

    before(:each) do
      @login_user = FactoryBot.create(:admin)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)
      @object = FactoryBot.create(:sound)
      CollectionLock.create(collection_id: @collection.alternate_id)

      request.env["HTTP_REFERER"] = my_collections_path(@collection.alternate_id)
    end

    after(:each) do
      CollectionLock.where(collection_id: @collection.alternate_id).delete_all
      @collection.delete if DRI::Identifier.object_exists?(@collection.alternate_id)
      @login_user.delete
    end

    it 'should not allow object creation' do
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { digital_object: { governing_collection: @collection.alternate_id }, metadata_file: @file }
      expect(flash[:error]).to be_present
    end

    it 'should not allow object updates' do
      @object.governing_collection = @collection
      @object.save

      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["An Audio Title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      put :update, params: { id: @object.alternate_id, digital_object: params[:digital_object] }

      expect(flash[:error]).to be_present
    end
  end
end
