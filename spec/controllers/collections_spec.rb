describe CollectionsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'DELETE destroy' do

    it 'should delete a collection' do
      @collection = DRI::Batch.with_standard :qdc
      @collection[:title] = ["A collection"]
      @collection[:description] = ["This is a Collection"]
      @collection[:rights] = ["This is a statement about the rights associated with this object"]
      @collection[:publisher] = ["RnaG"]
      @collection[:creator] = ["Creator"]
      @collection[:resource_type] = ["Collection"]
      @collection[:creation_date] = ["1916-01-01"]
      @collection[:published_date] = ["1916-04-01"]
      @collection.save
      
      @object = DRI::Batch.with_standard :qdc
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
      delete :destroy, :id => @collection.id
    end

  end

  describe 'publish' do

    it 'should publish a collection' do
      @collection = DRI::Batch.with_standard :qdc
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

      @object = DRI::Batch.with_standard :qdc
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
 
      expect(PublishCollectionJob).to receive(:create)
      post :publish, id: @collection.id
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
      @collection.delete
    end

    it 'should return not-found for no cover image' do
      get :cover, { id: @collection.id }
      expect(response.status).to eq(404)
    end

    it 'should return not found if cover image cannot be found for storage interface' do
      get :cover, { id: @collection.id }
      expect(response.status).to eq(404)
    end

    it 'accepts a valid image' do
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_image.jpeg"), "image/jpeg")
      put :add_cover_image, { id: @collection.id, batch: { cover_image: @uploaded } }
      expect(flash[:notice]).to be_present
    end

    it 'rejects unsupported image format' do
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_image.tiff"), "image/tiff")
      put :add_cover_image, { id: @collection.id, batch: { cover_image: @uploaded } }
      expect(flash[:error]).to be_present
    end

    it 'creates new AIP' do
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_image.jpeg"), "image/jpeg")
      put :add_cover_image, { id: @collection.id, batch: { cover_image: @uploaded } }

      expect(Dir.entries(aip_dir(@collection.id)).size - 2).to eq(2)
      expect(aip_valid?(@collection.id, 2)).to be true
    end

  end

  describe 'update' do
    
    it 'should allow a subcollection to be updated' do
      @collection = DRI::Batch.with_standard :qdc
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
      preservation.preserve(false, false, ['descMetadata','properties'])

      @subcollection = DRI::Batch.with_standard :qdc
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
      preservation.preserve(false, false, ['descMetadata','properties'])

      @collection.governed_items << @subcollection
      @collection.reload
      @subcollection.reload
 
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified sub collection title"]
      put :update, :id => @subcollection.id, :batch => params[:batch]
      @subcollection.reload
      expect(@subcollection.title).to eq(["A modified sub collection title"])

      @collection.delete
    end

    it 'should mint a doi for an update of mandatory fields' do
      @collection = DRI::Batch.with_standard :qdc
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
      preservation.preserve(false, false, ['descMetadata','properties'])

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

      DataciteDoi.create(object_id: @collection.id)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A modified title"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @collection.id).first.delete
      Settings.doi.enable = false
    end

    it 'should not mint a doi for no update of mandatory fields' do
      @collection = DRI::Batch.with_standard :qdc
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
      preservation.preserve(false, false, ['descMetadata','properties'])

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

      DataciteDoi.create(object_id: @collection.id)

      expect(DRI.queue).to_not receive(:push).with(an_instance_of(MintDoiJob))
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A collection"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

      DataciteDoi.where(object_id: @collection.id).first.delete
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

      post :create, :metadata_file => @file
      expect(response).to be_success    
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
      
      request.env["HTTP_REFERER"] = catalog_index_path
    end

    after(:each) do
      @collection.delete if ActiveFedora::Base.exists?(@collection.id)
      @login_user.delete

      Settings.reload_from_files(
        Rails.root.join("config", "settings.yml").to_s
      )
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

      post :create, metadata_file: @file
      expect(flash[:error]).to be_present
    end

    it 'should not allow object updates' do
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A collection"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

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
      CollectionLock.create(collection_id: @collection.id)
      
      request.env["HTTP_REFERER"] = catalog_index_path
    end

    after(:each) do
      CollectionLock.delete_all(collection_id: @collection.id)
      @collection.delete if ActiveFedora::Base.exists?(@collection.id)
      @login_user.delete

      FileUtils.remove_dir(@tmp_assets_dir, force: true)
    end

    it 'should not allow object updates' do
      params = {}
      params[:batch] = {}
      params[:batch][:title] = ["A collection"]
      params[:batch][:read_users_string] = "public"
      params[:batch][:edit_users_string] = @login_user.email
      put :update, :id => @collection.id, :batch => params[:batch]

      expect(flash[:error]).to be_present
    end

  end
end
