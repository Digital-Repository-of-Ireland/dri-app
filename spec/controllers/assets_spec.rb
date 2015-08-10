require 'spec_helper'

describe AssetsController do
  include Devise::TestHelpers

  before(:each) do
    @login_user = FactoryGirl.create(:admin)
    sign_in @login_user

    @collection = FactoryGirl.create(:collection)
   
    @object = FactoryGirl.create(:sound) 
    @object[:status] = "draft"
    @object.save

    @collection.governed_items << @object

    @collection.save    

    @tmp_upload_dir = Dir.mktmpdir
    @tmp_assets_dir = Dir.mktmpdir

    Settings.dri.uploads = @tmp_upload_dir
    Settings.dri.files = @tmp_assets_dir
  end

  after(:each) do
    @collection.delete
    @login_user.delete
    FileUtils.remove_dir(@tmp_upload_dir, :force => true)
    FileUtils.remove_dir(@tmp_assets_dir, :force => true)
  end

  describe 'create' do

    it 'should create an asset from a local file' do
      DRI::Asset::Actor.any_instance.stub(:create_external_content)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))
      options = { :file_name => "SAMPLEA.mp3" }      
      post :create, { :object_id => @object.id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }
       
      expect(Dir.glob("#{@tmp_assets_dir}/**/SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create an asset from an upload' do
      DRI::Asset::Actor.any_instance.stub(:create_external_content)

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, { :object_id => @object.id, :Filedata => @uploaded }

      expect(Dir.glob("#{@tmp_assets_dir}/**/SAMPLEA.mp3")).not_to be_empty
    end

   end

   describe 'update' do  
    it 'should create a new version' do
      DRI::Asset::Actor.any_instance.stub(:create_external_content)
      DRI::Asset::Actor.any_instance.stub(:update_external_content)

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
       
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      @uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      put :update, { :object_id => @object.id, :id => file_id, :Filedata => @uploaded }
      expect(Dir.glob("#{@tmp_assets_dir}/**/content1/SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create a new version from a local file' do
      DRI::Asset::Actor.any_instance.stub(:create_external_content)
      DRI::Asset::Actor.any_instance.stub(:update_external_content)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(@tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata('test@test.com')
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      file.add_file File.new(File.join(@tmp_upload_dir, "SAMPLEA.mp3")), options
      file.save
      generic_file.save
      file_id = generic_file.id

      put :update, { :object_id => @object.id, :id => file_id, :local_file => "SAMPLEA.mp3", :file_name => "SAMPLEA.mp3" }
      expect(Dir.glob("#{@tmp_assets_dir}/**/content1/SAMPLEA.mp3")).not_to be_empty
    end

  end

end
