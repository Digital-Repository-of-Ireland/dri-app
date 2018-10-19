require 'rails_helper'

describe ObjectsController do
  include Devise::Test::ControllerHelpers

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
        delete :destroy, :id => object.id
      }.to change { ActiveFedora::Base.exists?(object.id) }.from(true).to(false)

      collection.reload
      collection.delete
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

      delete :destroy, :id => @object.id

      expect(ActiveFedora::Base.exists?(@object.id)).to be true

      @collection.reload
      @collection.delete
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

      delete :destroy, :id => @object.id

      expect(ActiveFedora::Base.exists?(@object.id)).to be false

      @collection.reload
      @collection.delete
    end

  end

  describe 'create' do

    before(:each) do
      @login_user = FactoryBot.create(:admin)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)
    end

    after(:each) do
      @collection.delete if ActiveFedora::Base.exists?(@collection.id)
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

      post :create, batch: { governing_collection: @collection.id }, metadata_file: @file
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

      post :create, batch: { governing_collection: @collection.id }, metadata_file: @file
      expect(flash[:error]).to match(/Validation Errors/)
      expect(response.status).to eq(400)
    end

  end


  describe 'status' do

    before(:each) do
      @login_user = FactoryBot.create(:collection_manager)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)
      @collection.depositor = User.find_by_email(@login_user.email).to_s
      @collection.manager_users_string=User.find_by_email(@login_user.email).to_s
      @collection.discover_groups_string="public"
      @collection.read_groups_string="registered"
      @collection.creator = [@login_user.email]

      @subcollection = FactoryBot.create(:collection)
      @subcollection.depositor = User.find_by_email(@login_user.email).to_s
      @subcollection.manager_users_string=User.find_by_email(@login_user.email).to_s
      @subcollection.discover_groups_string="public"
      @subcollection.read_groups_string="registered"
      @subcollection.creator = [@login_user.email]
      @subcollection.status = 'draft'

      @subsubcollection = FactoryBot.create(:collection)
      @subsubcollection.depositor = User.find_by_email(@login_user.email).to_s
      @subsubcollection.manager_users_string=User.find_by_email(@login_user.email).to_s
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
      @object2.delete
      @object.delete if ActiveFedora::Base.exists?(@object.id)
      @collection.delete if ActiveFedora::Base.exists?(@collection.id)
      @login_user.delete
    end

    it 'should set an object status' do
      post :status, id: @object.id, status: "reviewed"

      @object.reload

      expect(@object.status).to eql("reviewed")

      post :status, id: @object.id, status: "draft"

      @object.reload

      expect(@object.status).to eql("draft")
    end

    it 'should set a parent subcollection to reviewed' do
      post :status, id: @object4.id, status: "reviewed"

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

      post :status, id: @object.id, status: "draft"

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
      DataciteDoi.create(object_id: @object.id)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @object.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @object.id).first.delete
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
      DataciteDoi.create(object_id: @object.id)

      expect(DRI.queue).to_not receive(:push).with(an_instance_of(MintDoiJob))
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["An Audio Title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @object.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @object.id).first.delete
      Settings.doi.enable = false
    end

  end

  describe "read only is set" do

      before(:each) do
        Settings.reload_from_files(
          Rails.root.join(fixture_path, "settings-ro.yml").to_s
        )
        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @login_user = FactoryBot.create(:admin)
        sign_in @login_user
        @collection = FactoryBot.create(:collection)
        @object = FactoryBot.create(:sound)

        request.env["HTTP_REFERER"] = catalog_path(@collection.id)
      end

      after(:each) do
        @collection.delete if ActiveFedora::Base.exists?(@collection.id)
        @login_user.delete

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(
          Rails.root.join("config", "settings.yml").to_s
        )
      end

      it 'should not allow object creation' do
        @request.env["CONTENT_TYPE"] = "multipart/form-data"

        @file = fixture_file_upload("/valid_metadata.xml", "text/xml")
        class << @file
          # The reader method is present in a real invocation,
          # but missing from the fixture object for some reason (Rails 3.1.1)
          attr_reader :tempfile
        end

        post :create, batch: { governing_collection: @collection.id }, metadata_file: @file
        expect(flash[:error]).to be_present
      end

      it 'should not allow object updates' do
        params = {}
        params[:batch] = {}
        params[:batch][:title] = ["An Audio Title"]
        params[:batch][:read_users_string] = "public"
        params[:batch][:edit_users_string] = @login_user.email
        put :update, :id => @object.id, :batch => params[:batch]

        expect(flash[:error]).to be_present
      end

  end

  describe "collection is locked" do

      before(:each) do
        @login_user = FactoryBot.create(:admin)
        sign_in @login_user
        @collection = FactoryBot.create(:collection)
        @object = FactoryBot.create(:sound)
        CollectionLock.create(collection_id: @collection.id)

        request.env["HTTP_REFERER"] = catalog_path(@collection.id)
      end

      after(:each) do
        CollectionLock.delete_all(collection_id: @collection.id)
        @collection.delete if ActiveFedora::Base.exists?(@collection.id)
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

        post :create, batch: { governing_collection: @collection.id }, metadata_file: @file
        expect(flash[:error]).to be_present
      end

      it 'should not allow object updates' do
        @object.governing_collection = @collection
        @object.save

        params = {}
        params[:batch] = {}
        params[:batch][:title] = ["An Audio Title"]
        params[:batch][:read_users_string] = "public"
        params[:batch][:edit_users_string] = @login_user.email
        put :update, :id => @object.id, :batch => params[:batch]

        expect(flash[:error]).to be_present
      end

  end

  describe 'get_objects' do

    before(:each) do
      @login_user = FactoryBot.create(:admin)
      sign_in @login_user

      @object = FactoryBot.create(:sound)
      @object.status = 'published'
      @object.save
    end

    after(:each) do
      @object.delete
      @login_user.delete
    end

    it 'should assign valid JSON to @list' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :index, objects: [{ 'pid' => @object.id }]
      list = controller.instance_variable_get(:@list)
      expect { JSON.parse(list.to_json) }.not_to raise_error
    end

    it 'should contain the metadata fields' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :index, objects: [{ 'pid' => @object.id }]
      list = controller.instance_variable_get(:@list)
      json = JSON.parse(list.to_json)

      expect(json.first['metadata']['title']).to eq(@object.title)
      expect(json.first['metadata']['description']).to eq(@object.description)
      expect(json.first['metadata']['contributor']).to eq(@object.contributor)
    end

    it 'should only return the requested fields' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :index, objects: [{ 'pid' => @object.id }], metadata: ['title', 'description']
      list = controller.instance_variable_get(:@list)
      json = JSON.parse(list.to_json)

      expect(json.first['metadata']['title']).to eq(@object.title)
      expect(json.first['metadata']['description']).to eq(@object.description)
      expect(json.first['metadata']['contributor']).to be nil
    end

    it 'should include assets and surrogates' do
      @gf = DRI::GenericFile.new
      @gf.apply_depositor_metadata(@login_user)
      @gf.batch = @object
      @gf.save

      storage = StorageService.new
      storage.create_bucket(@object.id)
      storage.store_surrogate(@object.id, File.join(fixture_path, "SAMPLEA.mp3"), "#{@gf.id}_mp3.mp3")

      request.env["HTTP_ACCEPT"] = 'application/json'
      post :index, objects: [{ 'pid' => @object.id }]
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].first).to include('masterfile')
      expect(list.first['files'].first).to include('mp3')
    end
  end
end
