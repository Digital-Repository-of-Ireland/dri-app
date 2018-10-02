describe AssetsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_upload_dir = Dir.mktmpdir
    @tmp_assets_dir = Dir.mktmpdir

    Settings.dri.uploads = @tmp_upload_dir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)

    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object

    @collection.save
  end

  after(:each) do
    @collection.delete
    @login_user.delete
    FileUtils.remove_dir(@tmp_upload_dir, force: true)
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'create' do

    it 'should create an asset from a local file' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))
      options = { :file_name => "SAMPLEA.mp3" }
      post :create, { :object_id => @object.id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }

      expect(Dir.glob("#{@tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create a valid aip' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))
      options = { :file_name => "SAMPLEA.mp3" }
      post :create, { :object_id => @object.id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }

      expect(aip_valid?(@object.id, 2)).to be true
    end

    it 'should create an asset from an upload' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.id, :Filedata => @uploaded }

      expect(Dir.glob("#{@tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should mint a doi when an asset is added to a published object' do
      @object.status = "published"
      @object.save

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

      DataciteDoi.create(object_id: @object.id)

      expect_any_instance_of(GenericFileContent).to receive(:external_content).and_return(true)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.id, :Filedata => @uploaded }

      DataciteDoi.where(object_id: @object.id).first.delete
      Settings.doi.enable = false
    end

   end

   describe 'update' do
    it 'should create a new version' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.id}_SAMPLEA.mp3"
      options[:batch_id] = @object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      put :update, { :object_id => @object.id, :id => file_id, :Filedata => @uploaded }
      expect(Dir.glob("#{@tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create a valid aip' do
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.id, :Filedata => @uploaded }
      expect(aip_valid?(@object.id, 2)).to be true

      @object.reload
      file_id = @object.generic_files.first.id

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_image.jpeg"), "image/jpeg")
      put :update, { :object_id => @object.id, :id => file_id, :Filedata => @uploaded }

      expect(aip_valid?(@object.id, 3)).to be true
    end

    it 'should create a new version from a local file' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      file.add_file File.new(File.join(@tmp_upload_dir, "SAMPLEA.mp3")), options
      file.save
      generic_file.save
      file_id = generic_file.id

      put :update, { :object_id => @object.id, :id => file_id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }
      expect(Dir.glob("#{@tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should mint a doi when an asset is modified' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content).and_return(true)

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

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      file.add_file File.new(File.join(@tmp_upload_dir, "SAMPLEA.mp3")), options
      file.save
      generic_file.save
      file_id = generic_file.id

      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.id)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      put :update, { :object_id => @object.id, :id => file_id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }

      DataciteDoi.where(object_id: @object.id).each { |d| d.delete }
      Settings.doi.enable = false
    end

  end

  describe 'destroy' do

    it 'should delete a file' do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      expect {
        delete :destroy, object_id: @object.id, id: file_id
      }.to change { ActiveFedora::Base.exists?(file_id) }.from(true).to(false)

    end

  end

  describe 'download' do

    it "should be possible to download the master asset" do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      @object.master_file_access = 'public'
      @object.edit_users_string = @login_user.email
      @object.read_users_string = @login_user.email
      @object.save
      @object.reload

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      get :download, id: file_id, object_id: @object.id, type: 'masterfile'
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mp3')
      expect(response.header['Content-Length']).to eq("#{File.size(File.join(fixture_path, "SAMPLEA.mp3"))}")
    end
  end

  describe 'list_assets' do

    before(:each) do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      @object.master_file_access = 'public'
      @object.edit_users_string = @login_user.email
      @object.read_users_string = @login_user.email
      @object.save
      @object.reload

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      storage = StorageService.new
      storage.create_bucket(@object.id)
      storage.store_surrogate(@object.id, File.join(fixture_path, "SAMPLEA.mp3"), "#{generic_file.id}_mp3.mp3")
    end

    after(:each) do
      @object.delete
    end

    it "should return a list of asset information" do
      request.env["HTTP_ACCEPT"] = 'application/json'
      post :list_assets, objects: [ { "pid" => "#{@object.id}" } ]
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].first).to include('masterfile')
      expect(list.first['files'].first).to include('mp3')
    end

    it "should not return preservation only files" do
      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.preservation_only = 'true'
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save

      request.env["HTTP_ACCEPT"] = 'application/json'
      post :list_assets, objects: [ { "pid" => "#{@object.id}" } ]
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].count).to be 1
    end

  end

  describe 'read only' do

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

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(
          Rails.root.join("config", "settings.yml").to_s
        )
      end

    describe 'create' do

      it 'should not create an asset' do
        allow_any_instance_of(GenericFileContent).to receive(:external_content)

        @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
        post :create, { :object_id => @object.id, :Filedata => @uploaded }

        expect(flash[:error]).to be_present
      end
    end
  end

end
