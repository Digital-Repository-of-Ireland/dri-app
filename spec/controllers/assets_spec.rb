require 'rails_helper'

describe AssetsController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_upload_dir = Dir.mktmpdir
    @tmp_assets_dir = Dir.mktmpdir
    
    Settings.dri.uploads = @tmp_upload_dir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
   
    @object = FactoryGirl.create(:sound) 
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object

    @collection.save    
  end

  after(:each) do
    @collection.destroy
    @login_user.delete
    FileUtils.remove_dir(@tmp_upload_dir, :force => true)
    FileUtils.remove_dir(@tmp_assets_dir, :force => true)
  end

  describe 'show' do

    it 'should return 404 for a surrogate that does not exist' do
      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.save
      
      get :show, { object_id: @object.noid, id: generic_file.noid, surrogate: 'thumbnail' }
      expect(response.status).to eq(404)
    end

  end

  describe 'create' do

    it 'should create an asset from a local file' do
      allow_any_instance_of(DRI::Asset::Actor).to receive(:save_characterize_and_record_committer)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))
      options = { :file_name => "SAMPLEA.mp3" }      
      post :create, { object_id: @object.noid, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }
       
      expect(Dir.glob("#{@tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create an asset from an upload' do
      allow_any_instance_of(DRI::Asset::Actor).to receive(:save_characterize_and_record_committer)
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.noid, :Filedata => @uploaded }

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

      DataciteDoi.create(object_id: @object.noid)

      expect_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content).and_return(true)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.noid, :Filedata => @uploaded }

      DataciteDoi.where(object_id: @object.noid).first.delete
      Settings.doi.enable = false
    end

   end

   describe 'update' do  
    it 'should create a new version' do
      #allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
      #allow_any_instance_of(DRI::Asset::Actor).to receive(:update_external_content)

      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.noid}_SAMPLEA.mp3"
      options[:batch_id] = @object.noid
       
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.noid

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      put :update, { :object_id => @object.noid, :id => file_id, :Filedata => @uploaded }
      expect(Dir.glob("#{@tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create a new version from a local file' do
      #allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
      
      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.noid

      generic_file.add_file File.new(File.join(@tmp_upload_dir, "SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.noid

      put :update, { :object_id => @object.noid, :id => file_id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }
      expect(Dir.glob("#{@tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should mint a doi when an asset is modified' do
      allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
      allow_any_instance_of(DRI::Asset::Actor).to receive(:update_external_content).and_return(true)

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

      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.noid

      generic_file.add_file File.new(File.join(@tmp_upload_dir, "SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.noid

      @object.status = "published"
      @object.save
      DataciteDoi.create(object_id: @object.noid)

      expect(DRI.queue).to receive(:push).with(an_instance_of(MintDoiJob)).once
      put :update, { :object_id => @object.noid, :id => file_id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }
       
      DataciteDoi.where(object_id: @object.noid).each { |d| d.delete }
      Settings.doi.enable = false
    end

  end

  describe 'destroy' do
    
    it 'should delete a file' do
      allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
      
      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.noid
       
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.noid

      expect {
        delete :destroy, object_id: @object.noid, id: file_id
      }.to change { DRI::Identifier.object_exists?(file_id) }.from(true).to(false)
      
    end

  end

  describe 'download' do
  
    it "should be possible to download the master asset" do
      #allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
      allow_any_instance_of(DRI::Asset::Actor).to receive(:save_characterize_and_record_committer)
      @object.master_file_access = 'public'
      @object.edit_users_string = @login_user.email
      @object.read_users_string = @login_user.email
      @object.save
      @object.reload

      generic_file = DRI::GenericFile.new(noid: ActiveFedora::Noid::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.noid

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.noid

      get :download, id: file_id, object_id: @object.noid, type: 'masterfile'
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mp3')
      expect(response.header['Content-Length']).to eq("#{File.size(File.join(fixture_path, "SAMPLEA.mp3"))}")      
    end
  end

  describe 'read only' do

    before(:each) do
        Settings.reload_from_files(
          Rails.root.join(fixture_path, "settings-ro.yml").to_s
        )
        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @login_user = FactoryGirl.create(:admin)
        sign_in @login_user
        @object = FactoryGirl.create(:sound) 

        request.env["HTTP_REFERER"] = catalog_index_path
      end

      after(:each) do
        @object.delete if DRI::Identifier.object_exists?(@object.noid)
        @login_user.delete
        
        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(
          Rails.root.join("config", "settings.yml").to_s
        )
      end

    describe 'create' do

      it 'should not create an asset' do
        allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)

        @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
        post :create, { :object_id => @object.noid, :Filedata => @uploaded }
        
        expect(flash[:error]).to be_present
      end
    end
  end

end
