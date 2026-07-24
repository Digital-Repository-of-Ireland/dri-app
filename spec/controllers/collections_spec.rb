require 'rails_helper'

describe CollectionsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    @login_user.destroy
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'DELETE destroy' do

    it 'should delete a collection' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:creator] = ["Creator"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection.save

      @object = DRI::DigitalObject.with_standard :qdc
      @object[:title] = ["An Audio Title"]
      @object[:rights] = ["This is a statement about the rights associated with this object"]
      @object[:role_hst] = ["Collins, Michael"]
      @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
      @object[:language] = ["ga"]
      @object[:description] = ["This is an Audio file"]
      @object[:published_date] = ["1916-04-01"]
      @object[:creation_date] = ["1916-01-01"]
      @object[:source] = ["CD nnn nuig"]
      @object[:geographical_coverage] = ["Dublin"]
      @object[:temporal_coverage] = ["1900s"]
      @object[:subject] = ["Ireland","something else"]
      @object[:resource_type] = ["Sound"]
      @object.save

      @collection.governed_items << @object

      expect(@collection.governed_items.size).to be == 1

      expect(DRI.queue).to receive(:push).with(an_instance_of(DeleteCollectionJob)).once

      delete :destroy, params: { id: @collection.alternate_id }
    end

  end

  describe 'publish' do

    it 'should publish a collection' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:creator] = ["Creator"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      @object = DRI::DigitalObject.with_standard :qdc
      @object[:title] = ["An Audio Title"]
      @object[:rights] = ["This is a statement about the rights associated with this object"]
      @object[:role_hst] = ["Collins, Michael"]
      @object[:contributor] = ["DeValera, Eamonn", "Connolly, James"]
      @object[:language] = ["ga"]
      @object[:description] = ["This is an Audio file"]
      @object[:published_date] = ["1916-04-01"]
      @object[:creation_date] = ["1916-01-01"]
      @object[:source] = ["CD nnn nuig"]
      @object[:geographical_coverage] = ["Dublin"]
      @object[:temporal_coverage] = ["1900s"]
      @object[:subject] = ["Ireland","something else"]
      @object[:resource_type] = ["Sound"]
      @object[:status] = "draft"
      @object.save

      @collection.governed_items << @object

      expect(Resque).to receive(:enqueue).once

      post :publish, params: { id: @collection.alternate_id }
    end
  end

  describe 'cover' do

    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection[:creator] = [@login_user.email]
      @collection[:status] = "draft"
      @collection.save
    end

    after(:each) do
      @collection.send(:delete_bucket)
      @collection.destroy
    end

    it 'should return not-found for no cover image' do
      get :cover, params: { id: @collection.alternate_id }
      expect(response.status).to eq(404)
    end

    it 'should return not found if cover image cannot be found for storage interface' do
      get :cover, params: { id: @collection.alternate_id }
      expect(response.status).to eq(404)
    end

    it 'accepts a valid image' do
      @uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.jpeg"), "image/jpeg")
      put :add_cover_image, params: { id: @collection.alternate_id, digital_object: { cover_image: @uploaded } }
      expect(flash[:notice]).to be_present
    end

    it 'rejects unsupported image format' do
      @uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.tiff"), "image/tiff")
      put :add_cover_image, params: { id: @collection.alternate_id, digital_object: { cover_image: @uploaded } }
      expect(flash[:error]).to be_present
    end

    it 'creates new AIP' do
      @uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.jpeg"), "image/jpeg")
      put :add_cover_image, params: { id: @collection.alternate_id, digital_object: { cover_image: @uploaded } }

      expect(Dir.entries(aip_dir(@collection.alternate_id)).size - 2).to eq(2)
      expect(aip_valid?(@collection.alternate_id, 2)).to be true
    end

  end

  describe 'update' do

    it 'should allow a subcollection to be updated' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(['descMetadata'])

      @subcollection = DRI::DigitalObject.with_standard :qdc
      @subcollection[:title] = ["A sub collection"]
      @subcollection[:description] = ["This is a sub-collection"]
      @subcollection[:creator] = [@login_user.email]
      @subcollection[:rights] = ["This is a statement about the rights associated with this object"]
      @subcollection[:publisher] = ["RnaG"]
      @subcollection[:resource_type] = ["Collection"]
      @subcollection[:creation_date] = ["1916-01-01"]
      @subcollection[:published_date] = ["1916-04-01"]
      @subcollection[:status] = "draft"
      @subcollection.save

      preservation = Preservation::Preservator.new(@subcollection)
      preservation.preserve(['descMetadata'])

      @collection.governed_items << @subcollection
      @collection.reload
      @subcollection.reload

      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified sub collection title"]

      put :update, params: { id: @subcollection.alternate_id, digital_object: params[:digital_object] }
      @subcollection.reload
      expect(@subcollection.title).to eq(["A modified sub collection title"])

      @collection.destroy
    end

    it 'should update ancestors when title updated' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(['descMetadata'])

      @subcollection = DRI::DigitalObject.with_standard :qdc
      @subcollection[:title] = ["A sub collection"]
      @subcollection[:description] = ["This is a sub-collection"]
      @subcollection[:creator] = [@login_user.email]
      @subcollection[:rights] = ["This is a statement about the rights associated with this object"]
      @subcollection[:publisher] = ["RnaG"]
      @subcollection[:resource_type] = ["Collection"]
      @subcollection[:creation_date] = ["1916-01-01"]
      @subcollection[:published_date] = ["1916-04-01"]
      @subcollection[:status] = "draft"
      @subcollection.save

      preservation = Preservation::Preservator.new(@subcollection)
      preservation.preserve(['descMetadata'])

      @collection.governed_items << @subcollection
      @collection.reload
      @subcollection.reload

      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified collection title"]

      expect(Resque).to receive(:enqueue).with(UpdateDescendantsJob, @collection.alternate_id)
      put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] }
      
      @collection.destroy
    end

    it 'should not update ancestors when title not changed' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "draft"
      @collection.save

      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(['descMetadata'])

      @subcollection = DRI::DigitalObject.with_standard :qdc
      @subcollection[:title] = ["A sub collection"]
      @subcollection[:description] = ["This is a sub-collection"]
      @subcollection[:creator] = [@login_user.email]
      @subcollection[:rights] = ["This is a statement about the rights associated with this object"]
      @subcollection[:publisher] = ["RnaG"]
      @subcollection[:resource_type] = ["Collection"]
      @subcollection[:creation_date] = ["1916-01-01"]
      @subcollection[:published_date] = ["1916-04-01"]
      @subcollection[:status] = "draft"
      @subcollection.save

      preservation = Preservation::Preservator.new(@subcollection)
      preservation.preserve(['descMetadata'])

      @collection.governed_items << @subcollection
      @collection.reload
      @subcollection.reload

      params = {}
      params[:digital_object] = {}
      params[:digital_object][:description] = ["This is modified Collection"]

      expect(Resque).to_not receive(:enqueue).with(UpdateDescendantsJob, @collection.alternate_id)
      put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] }
      
      @collection.destroy
    end

    it 'should rollback changes when an update fails' do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string=@login_user.email
      @collection.discover_groups_string="public"
      @collection.read_groups_string="registered"
      @collection.creator = [@login_user.email]
      @collection.save

      title = @collection.title

      expect_any_instance_of(DRI::DigitalObject)
        .to receive(:update_index).and_return(false)
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email

      put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] }

      @collection.reload
      expect(@collection.title).to eq(title)
      @collection.destroy
    end

    it 'should mint a doi for an update of mandatory fields' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "published"
      @collection.save

      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(['descMetadata'])

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

      DataciteDoi.create(object_id: @collection.alternate_id)

      expect(Resque).to receive(:enqueue).with(MintDoiJob, 2)
      params = {}

      params[:digital_object] = {}
      params[:digital_object][:title] = ["A modified title"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      expect { put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] } }.to change{ DataciteDoi.count }.by(1)

      DataciteDoi.where(object_id: @collection.alternate_id).first.delete
      Settings.doi.enable = false
    end

    it 'should not mint a doi for no update of mandatory fields' do
      @collection = DRI::DigitalObject.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:creator] = [@login_user.email]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection[:status] = "published"
      @collection.save

      preservation = Preservation::Preservator.new(@collection)
      preservation.preserve(['descMetadata'])

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

      DataciteDoi.create(object_id: @collection.alternate_id)

      expect(Resque).to_not receive(:enqueue).with(MintDoiJob, 2)
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A collection"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      expect { put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] } }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: @collection.alternate_id).first.delete
      Settings.doi.enable = false
    end

  end

  describe 'ingest' do

    it 'should create a collection from a metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/collection_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { metadata_file: @file }
      expect(response).to be_successful
    end

    it 'should set visibility' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/collection_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { metadata_file: @file }
      expect(response).to be_successful

      c = DRI::DigitalObject.find_by_alternate_id(response.parsed_body['id'])
      expect(c.visibility).to eq 'public'
    end
  end

  describe "read only is set" do

    before(:each) do
      Settings.add_source!(
                        file_fixture("settings-ro.yml").to_s
      )
      Settings.reload!
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:admin)
      sign_in @login_user
      @collection = FactoryBot.create(:collection)

      request.env["HTTP_REFERER"] = search_catalog_path
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
      @login_user.destroy

      Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'should not allow object creation' do
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      @file = fixture_file_upload("/collection_metadata.xml", "text/xml")
      class << @file
        # The reader method is present in a real invocation,
        # but missing from the fixture object for some reason (Rails 3.1.1)
        attr_reader :tempfile
      end

      post :create, params: { metadata_file: @file }
      expect(flash[:error]).to be_present
    end

    it 'should not allow object updates' do
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A collection"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] }

      expect(flash[:error]).to be_present
    end

  end

  describe "collection is locked" do

    before(:each) do
      @tmp_assets_dir = Dir.mktmpdir
      Settings.dri.files = @tmp_assets_dir

      @login_user = FactoryBot.create(:admin)
      sign_in @login_user

      @collection = FactoryBot.create(:collection)
      CollectionLock.create(collection_id: @collection.alternate_id)

      request.env["HTTP_REFERER"] = search_catalog_path
    end

    after(:each) do
      CollectionLock.where(collection_id: @collection.alternate_id).delete_all
      @collection.destroy if DRI::DigitalObject.exists?(@collection.alternate_id)
      @login_user.destroy

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'should not allow object updates' do
      params = {}
      params[:digital_object] = {}
      params[:digital_object][:title] = ["A collection"]
      params[:digital_object][:read_users_string] = "public"
      params[:digital_object][:edit_users_string] = @login_user.email
      put :update, params: { id: @collection.alternate_id, digital_object: params[:digital_object] }

      expect(flash[:error]).to be_present
    end

    # NOTE: :new/:create are intentionally excluded from the `locked`
    # before_action's except-list check (see the controller's
    # `except: %i[index cover lock new create]`), so they should work
    # normally even while some collection is locked.
    it 'still allows access to the new collection form despite another collection being locked' do
      get :new

      expect(response).to be_successful
    end
  end

  # NOTE: several tests below sign in via `FactoryBot.create(:user)` to get
  # a signed-in user with no special admin/collection-manager privileges,
  # to exercise permission-denial branches. If this app doesn't have a
  # plain `:user` factory (as opposed to `:admin`/`:collection_manager`),
  # these will need a different non-privileged factory/trait.

  describe 'new' do
    it 'sets sensible defaults for a fresh collection object' do
      get :new

      object = assigns(:object)
      expect(object.type).to eq(['Collection'])
      expect(object.title).to eq([''])
      expect(object.creator).to eq([''])
      expect(object.discover_groups_string).to eq('public')
      expect(object.read_groups_string).to eq('public')
      expect(object.master_file_access).to eq('private')
    end

    it 'denies a signed-in user who is not a collection manager or admin' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user
      request.env["HTTP_REFERER"] = search_catalog_path

      get :new

      expect(flash[:error]).to be_present

      @plain_user.destroy
    end
  end

  describe 'edit' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'loads the collection for editing' do
      get :edit, params: { id: @collection.alternate_id }

      expect(response).to be_successful
      expect(assigns(:object).alternate_id).to eq(@collection.alternate_id)
    end

    it 'warns when the collection is published and has a doi' do
      @collection.status = 'published'
      @collection.doi = ['10.5072/example']
      @collection.save

      get :edit, params: { id: @collection.alternate_id }

      expect(flash[:alert]).to be_present
    end

    it 'does not warn when the published collection has no doi' do
      @collection.status = 'published'
      @collection.save

      get :edit, params: { id: @collection.alternate_id }

      expect(flash[:alert]).to be_nil
    end
  end

  describe 'lock' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.save
    end

    after(:each) do
      CollectionLock.where(collection_id: @collection.alternate_id).delete_all
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'denies non-admin users, even collection managers' do
      sign_out @login_user
      @manager = FactoryBot.create(:collection_manager)
      sign_in @manager

      expect {
        post :lock, params: { id: @collection.alternate_id }
      }.to_not change { CollectionLock.where(collection_id: @collection.alternate_id).count }

      @manager.destroy
    end

    it 'returns a bad request when the target is not a collection' do
      @object = FactoryBot.create(:sound)
      @object.save

      post :lock, params: { id: @object.alternate_id }

      expect(response.status).to eq(400)

      @object.destroy
    end

    it 'creates a collection lock on POST' do
      expect {
        post :lock, params: { id: @collection.alternate_id }
      }.to change { CollectionLock.where(collection_id: @collection.alternate_id).count }.by(1)

      expect(flash[:notice]).to be_present
    end

    it 'removes the collection lock on DELETE' do
      CollectionLock.create(collection_id: @collection.alternate_id)

      expect {
        delete :lock, params: { id: @collection.alternate_id }
      }.to change { CollectionLock.where(collection_id: @collection.alternate_id).count }.by(-1)

      expect(flash[:notice]).to be_present
    end
  end

  describe 'add_cover_image validations' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.send(:delete_bucket)
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'returns a bad request when no cover image is given' do
      put :add_cover_image, params: { id: @collection.alternate_id, digital_object: { cover_image: '' } }

      expect(response.status).to eq(400)
    end
  end

  describe 'cover with an externally-hosted image' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.cover_image = 'https://example.com/cover.jpg'
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'redirects directly to the external image url instead of streaming a file' do
      get :cover, params: { id: @collection.alternate_id }

      expect(response).to redirect_to('https://example.com/cover.jpg')
    end
  end

  # NOTE: as currently written, BaseObjectsController#set_licence saves
  # unconditionally and only skips `increment_version` when no licence is
  # given - it doesn't require a licence value at all. The test below
  # expects a fix requiring the value (flash[:error], no save/preserve
  # attempted) rather than the current silent-no-op-then-preserve-error
  # behavior.
  describe 'set_licence' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'requires a licence value - omitting it should not proceed to save/preserve' do
      put :set_licence, params: { id: @collection.alternate_id, digital_object: { licence: '' } }

      expect(flash[:error]).to be_present
      expect(flash[:notice]).to be_nil
    end

    it 'denies a non-manager' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      put :set_licence, params: { id: @collection.alternate_id, digital_object: { licence: '' } }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end
  end

  # NOTE: same fix expected as set_licence above - a copyright value
  # should be required, not silently optional.
  describe 'set_copyright' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'requires a copyright value - omitting it should not proceed to save/preserve' do
      put :set_copyright, params: { id: @collection.alternate_id, digital_object: { copyright: '' } }

      expect(flash[:error]).to be_present
      expect(flash[:notice]).to be_nil
    end

    it 'denies a non-manager' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      put :set_copyright, params: { id: @collection.alternate_id, digital_object: { copyright: '' } }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end
  end

  describe 'review' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.status = 'draft'
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'returns a bad request when the target is not a collection' do
      @object = FactoryBot.create(:sound)
      @object.save

      post :review, params: { id: @object.alternate_id }

      expect(response.status).to eq(400)

      @object.destroy
    end

    it 'denies a non-manager' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      post :review, params: { id: @collection.alternate_id }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end

    it 'enqueues a review job for descendants when apply_all is requested' do
      @object = FactoryBot.create(:sound)
      @object.save
      @collection.governed_items << @object
      @collection.save

      expect(Resque).to receive(:enqueue).with(ReviewCollectionJob, @collection.alternate_id, @login_user.id)

      post :review, params: { id: @collection.alternate_id, apply_all: 'yes' }

      expect(flash[:notice]).to be_present

      @object.destroy
    end

    it 'does not enqueue a review job when apply_all is not requested' do
      expect(Resque).to_not receive(:enqueue)

      post :review, params: { id: @collection.alternate_id }
    end
  end

  describe 'publish validations' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'returns a bad request when the target is not a collection' do
      @object = FactoryBot.create(:sound)
      @object.save

      post :publish, params: { id: @object.alternate_id }

      expect(response.status).to eq(400)

      @object.destroy
    end

    it 'denies a non-manager' do
      sign_out @login_user
      @plain_user = FactoryBot.create(:user)
      sign_in @plain_user

      post :publish, params: { id: @collection.alternate_id }

      expect(response.status).to eq(401)

      @plain_user.destroy
    end

    it 'flashes an alert instead of raising when the publish job fails to enqueue' do
      allow(Resque).to receive(:enqueue).and_raise(StandardError, 'queue unavailable')

      post :publish, params: { id: @collection.alternate_id }

      expect(flash[:alert]).to be_present
    end
  end

  describe 'destroy validations' do
    it 'denies deleting a published collection for a non-admin manager' do
      sign_out @login_user
      @manager = FactoryBot.create(:collection_manager)
      sign_in @manager

      @collection = FactoryBot.create(:collection)
      @collection.depositor = @manager.email
      @collection.manager_users_string = @manager.email
      @collection.creator = [@manager.email]
      @collection.status = 'published'
      @collection.save

      delete :destroy, params: { id: @collection.alternate_id }

      expect(response.status).to eq(401)

      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
      @manager.destroy
    end
  end

  describe 'check_for_cancel' do
    before(:each) do
      @collection = FactoryBot.create(:collection)
      @collection.depositor = @login_user.email
      @collection.manager_users_string = @login_user.email
      @collection.creator = [@login_user.email]
      @collection.save
    end

    after(:each) do
      @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    end

    it 'redirects without applying changes when the cancel button is used' do
      original_title = @collection.title

      put :update, params: {
        id: @collection.alternate_id,
        commit: I18n.t('dri.views.objects.buttons.cancel'),
        digital_object: { title: ['Should not be applied'] }
      }

      expect(response).to redirect_to(controller: 'my_collections', action: 'show', id: @collection.alternate_id)

      @collection.reload
      expect(@collection.title).to eq(original_title)
    end
  end

  describe 'create validations' do
    it 'returns a bad request for an invalid metadata file' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      @request.env["CONTENT_TYPE"] = "multipart/form-data"

      bad_file = Tempfile.new(['bad_metadata', '.xml'])
      bad_file.write('this is not valid xml')
      bad_file.rewind
      @file = Rack::Test::UploadedFile.new(bad_file.path, 'text/xml')

      post :create, params: { metadata_file: @file }

      expect(response.status).to eq(400)

      bad_file.close
      bad_file.unlink
    end

    it 'flashes an alert and re-renders the form when manager/editor permissions are missing from create params' do
      post :create, params: { digital_object: { title: ['A collection'] } }

      expect(flash[:alert]).to be_present
      expect(response).to be_successful
    end
  end

  describe 'index' do
    it 'returns a successful json response' do
      get :index, params: { format: :json }

      expect(response).to be_successful
    end
  end
end