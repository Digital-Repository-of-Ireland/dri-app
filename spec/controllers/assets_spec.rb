require 'rails_helper'

describe AssetsController do
  include Devise::Test::ControllerHelpers

  let(:tmp_upload_dir) { Dir.mktmpdir }
  let(:tmp_assets_dir) { Dir.mktmpdir }
  let(:login_user) { FactoryBot.create(:admin) }

  let(:collection) { FactoryBot.create(:collection) }
  let(:object) { FactoryBot.create(:sound) }

  before(:each) do
    Settings.dri.uploads = tmp_upload_dir
    Settings.dri.files = tmp_assets_dir

    sign_in login_user

    object.status = "draft"
    object.save

    collection.governed_items << object
    collection.save
  end

  after(:each) do
    collection.delete
    login_user.delete
    FileUtils.remove_dir(tmp_upload_dir, force: true)
    FileUtils.remove_dir(tmp_assets_dir, force: true)
  end

  describe 'create' do

    it 'should create an asset from a local file' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))
      options = { file_name: "SAMPLEA.mp3" }
      post :create, params: { object_id: object.alternate_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

     it 'should create a valid aip' do
       allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

       FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))
       options = { file_name: "SAMPLEA.mp3" }
       post :create, params: { object_id: object.alternate_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }

       expect(aip_valid?(object.alternate_id, 2)).to be true
     end

    it 'should create an asset from an upload' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, Filedata: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should remove the upload if save fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)
      expect_any_instance_of(DRI::GenericFile)
        .to receive(:save).and_return(false)

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, Filedata: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).to be_empty
    end

    it 'rollback an an asset save if indexing fails' do
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:update_index).and_return(false)
      expect {
        post :create, params: { object_id: object.alternate_id, Filedata: uploaded }
      }.to change{ DRI::GenericFile.count }.by(0)
    end

    it 'should mint a doi when an asset is added to a published object' do
      object.status = "published"
      object.depositor = 'test'
      object.save
      object.reload

      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { username: "user",
            password: "password",
            prefix: '10.5072',
            base_url: "http://repository.dri.ie",
            publisher: "Digital Repository of Ireland" }
        )
      )
      Settings.doi.enable = true

      DataciteDoi.create(object_id: object.alternate_id)

      expect_any_instance_of(GenericFileContent).to receive(:push_characterize_job).and_return(true)

      expect(Resque).to receive(:enqueue).once
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      expect { post :create, params: { object_id: object.alternate_id, Filedata: uploaded } }.to change{ DataciteDoi.count }.by(1)

      DataciteDoi.where(object_id: object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'should not mint a doi when there is a failure adding an asset to a published object' do
      object.status = "published"
      object.depositor = 'test'
      object.save
      object.reload

      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { username: "user",
            password: "password",
            prefix: '10.5072',
            base_url: "http://repository.dri.ie",
            publisher: "Digital Repository of Ireland" }
        )
      )
      Settings.doi.enable = true

      DataciteDoi.create(object_id: object.alternate_id)

      expect_any_instance_of(GenericFileContent).to receive(:add_content).and_return(false)

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      expect {
        post :create, params: { object_id: object.alternate_id, Filedata: uploaded }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: object.alternate_id).destroy_all
      Settings.doi.enable = false
    end
   end

   describe 'update' do
    it 'should create a new version' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.alternate_id}_SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, Filedata: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should create a valid aip' do
      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, Filedata: uploaded }
      expect(aip_valid?(object.alternate_id, 2)).to be true

      object.reload
      file_id = object.generic_files.first.alternate_id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "sample_image.jpeg"), "image/jpeg")
      put :update, params: { object_id: object.alternate_id, id: file_id, Filedata: uploaded }

      expect(aip_valid?(object.alternate_id, 3)).to be true
    end

    it 'rollback an an asset save if indexing fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.alternate_id}_SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:update_index).and_return(false)
      expect {
        put :update, params: { object_id: object.alternate_id, id: file_id, Filedata: uploaded }
      }.to change{ DRI::GenericFile.count }.by(0)
    end

    it 'should create a new version from a local file' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      generic_file.add_file File.new(File.join(tmp_upload_dir, "SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.alternate_id

      put :update, params: { object_id: object.alternate_id, id: file_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }
      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should remove the upload if save fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)
      expect_any_instance_of(DRI::GenericFile)
        .to receive(:save).and_return(false)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.alternate_id}_SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options

      generic_file.save
      file_id = generic_file.alternate_id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, Filedata: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).to be_empty
      expect(File.exist?(generic_file.path)).to be true
    end

    it 'should mint a doi when an asset is modified' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job).and_return(true)

      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { username: "user",
            password: "password",
            prefix: '10.5072',
            base_url: "http://repository.dri.ie",
            publisher: "Digital Repository of Ireland" }
        )
      )
      Settings.doi.enable = true

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      generic_file.add_file File.new(File.join(tmp_upload_dir, "SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.alternate_id

      object.status = "published"
      object.save
      DataciteDoi.create(object_id: object.alternate_id)

      expect(Resque).to receive(:enqueue).once
      expect { put :update, params: { object_id: object.alternate_id, id: file_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" } }.to change{ DataciteDoi.count }.by(1)

      DataciteDoi.where(object_id: object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'should not mint a doi when an asset modification fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job).and_return(true)

      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { username: "user",
            password: "password",
            prefix: '10.5072',
            base_url: "http://repository.dri.ie",
            publisher: "Digital Repository of Ireland" }
        )
      )
      Settings.doi.enable = true

      FileUtils.cp(File.join(fixture_path, "SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      generic_file.add_file File.new(File.join(tmp_upload_dir, "SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.alternate_id

      object.status = "published"
      object.save
      DataciteDoi.create(object_id: object.alternate_id)

      expect_any_instance_of(GenericFileContent)
        .to receive(:update_content).and_return(false)
      expect {
        put :update, params: { object_id: object.alternate_id, id: file_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }
      }.to change{ DataciteDoi.count }.by(0)

      DataciteDoi.where(object_id: object.alternate_id).destroy_all
      Settings.doi.enable = false
    end
  end

  describe 'destroy' do

    it 'should delete a file' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      expect {
        delete :destroy, params: { object_id: object.alternate_id, id: file_id }
      }.to change { DRI::Identifier.object_exists?(file_id) }.from(true).to(false)
    end

    it 'should mint a doi when an asset is deleted' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job).and_return(true)

      stub_const(
        'DoiConfig',
        OpenStruct.new(
          { username: "user",
            password: "password",
            prefix: '10.5072',
            base_url: "http://repository.dri.ie",
            publisher: "Digital Repository of Ireland" }
        )
      )
      Settings.doi.enable = true

      generic_file = DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      object.status = "published"
      object.save
      DataciteDoi.create(object_id: object.alternate_id)

      expect(Resque).to receive(:enqueue).once
      expect {
        delete :destroy, params: { object_id: object.alternate_id, id: file_id }
      }.to change{ DataciteDoi.count }.by(1)

      DataciteDoi.where(object_id: object.alternate_id).destroy_all
      Settings.doi.enable = false
    end
  end

  describe 'download' do

    it "should be possible to download the master asset" do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      object.master_file_access = 'public'
      object.edit_users_string = login_user.email
      object.read_users_string = login_user.email
      object.save
      object.reload

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      get :download, params: { id: file_id, object_id: object.alternate_id, type: 'masterfile' }

      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mp3')
      expect(response.header['Content-Length']).to eq("#{File.size(File.join(fixture_path, "SAMPLEA.mp3"))}")
    end
  end

  describe 'read only' do

    before(:each) do
        Settings.add_source!(
          Rails.root.join(fixture_path, "settings-ro.yml").to_s
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

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
      end

    describe 'create' do

      it 'should not create an asset' do
        allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

        uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
        post :create, params: { object_id: @object.alternate_id, Filedata: uploaded }

        expect(flash[:error]).to be_present
      end
    end
  end
end
