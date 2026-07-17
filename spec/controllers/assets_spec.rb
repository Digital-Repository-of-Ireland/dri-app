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

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))
      options = { file_name: "SAMPLEA.mp3" }
      post :create, params: { object_id: object.alternate_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

     it 'should create a valid aip' do
       allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

       FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))
       options = { file_name: "SAMPLEA.mp3" }
       post :create, params: { object_id: object.alternate_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }

       expect(aip_valid?(object.alternate_id, 2)).to be true
     end

    it 'should create an asset from an upload' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should update the object version' do
      version = object.object_version
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
      object.reload
      expect(object.object_version).to be > version
    end

    it 'should remove the upload if save fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)
      expect_any_instance_of(DRI::GenericFile)
        .to receive(:save).and_return(false)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3").reject { |f| f.include?('bin') }).to be_empty
    end

    it 'rollback an an asset save if indexing fails' do
      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:update_index).and_return(false)
      expect {
        post :create, params: { object_id: object.alternate_id, file: uploaded }
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
      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      expect { post :create, params: { object_id: object.alternate_id, file: uploaded } }.to change{ DataciteDoi.count }.by(1)

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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      expect {
        post :create, params: { object_id: object.alternate_id, file: uploaded }
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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should update the object version' do
      version = object.object_version
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "#{generic_file.alternate_id}_SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.jpeg"), "image/jpeg")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }
      object.reload
      expect(object.object_version).to be > version
    end

    it 'should create a valid aip' do
      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }
      expect(aip_valid?(object.alternate_id, 2)).to be true

      object.reload
      file_id = object.generic_files.first.alternate_id

      uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.jpeg"), "image/jpeg")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:update_index).and_return(false)
      expect {
        put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }
      }.to change{ DRI::GenericFile.count }.by(0)
    end

    it 'should create a new version from a local file' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      generic_file.add_file File.new(file_fixture("SAMPLEA.mp3")), options
      generic_file.save
      file_id = generic_file.alternate_id

      put :update, params: { object_id: object.alternate_id, id: file_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }
      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
    end

    it 'should not remove the file when trying to replace with matching file' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
      file = Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3").first
      file_id = Pathname.new(file).basename.to_s.split("_")[0]

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/#{file_id}_SAMPLEA.mp3")).to_not be_empty
    end

    it 'should not remove the file if save fails when replacing with matching file but different filenames' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
      file = Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3").first
      file_id = Pathname.new(file).basename.to_s.split("_")[0]

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:save).and_return(false)

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA_copy.mp3"))
      uploaded = Rack::Test::UploadedFile.new(File.join(tmp_upload_dir, "SAMPLEA_copy.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/#{file_id}_SAMPLEA.mp3")).to_not be_empty
    end

    it 'should remove the upload if save fails' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
      file = Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3").first
      file_id = Pathname.new(file).basename.to_s.split("_")[0]

      expect_any_instance_of(DRI::GenericFile)
        .to receive(:save).and_return(false)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("sample_image.jpeg"), "image/jpeg")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/data/content/#{file_id}_sample_image.jpeg").reject { |f| f.include?('bin') }).to be_empty
      expect(Dir.glob("#{tmp_assets_dir}/**/#{file_id}_SAMPLEA.mp3").reject { |f| f.include?('bin') }).not_to be_empty
    end

    it 'should raise an error if file is replaced with same contents' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))
      options = { file_name: "SAMPLEA.mp3" }
      post :create, params: { object_id: object.alternate_id, local_file: "SAMPLEA.mp3", file_name: "SAMPLEA.mp3" }

      expect(Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3")).not_to be_empty
      file = Dir.glob("#{tmp_assets_dir}/**/*_SAMPLEA.mp3").first
      file_id = Pathname.new(file).basename.to_s.split("_")[0]

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: file_id, file: uploaded }

      expect(Dir.glob("#{tmp_assets_dir}/**/v0002/data/content/*_SAMPLEA.mp3")).not_to be_empty
      expect(flash[:alert]).to be_present
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

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

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

      FileUtils.cp(file_fixture("SAMPLEA.mp3"), File.join(tmp_upload_dir, "SAMPLEA.mp3"))

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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      expect {
        delete :destroy, params: { object_id: object.alternate_id, id: file_id }
      }.to change { DRI::Identifier.object_exists?(file_id) }.from(true).to(false)
    end

    it 'should update the object version' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      version = object.object_version
      delete :destroy, params: { object_id: object.alternate_id, id: file_id }
      object.reload
      expect(object.object_version).to be > version
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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
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

    it 'should clean the index if file doesnt exist' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata('test@test.com')
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      DRI::GenericFile.where(id: generic_file.id).delete_all
      expect(SolrDocument.find(file_id)).not_to be_nil

      delete :destroy, params: { object_id: object.alternate_id, id: file_id }
      expect(SolrDocument.find(file_id)).to be_nil
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

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      get :download, params: { id: file_id, object_id: object.alternate_id, type: 'masterfile' }

      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mp3')
      expect(response.header['Content-Length']).to eq("#{file_fixture("SAMPLEA.mp3").size}")
    end
  end

  describe 'read only' do

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

        FileUtils.remove_dir(@tmp_assets_dir, force: true)
        Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
      end

    describe 'create' do

      it 'should not create an asset' do
        allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

        uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
        post :create, params: { object_id: @object.alternate_id, file: uploaded }

        expect(flash[:error]).to be_present
      end
    end

    describe 'update' do
      it 'should not update an asset' do
        generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
        generic_file.digital_object = @object
        generic_file.apply_depositor_metadata(@login_user.email)
        generic_file.save

        uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
        put :update, params: { object_id: @object.alternate_id, id: generic_file.alternate_id, file: uploaded }

        expect(flash[:error]).to be_present

        generic_file.destroy
      end
    end

    describe 'destroy' do
      it 'should not delete an asset' do
        generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
        generic_file.digital_object = @object
        generic_file.apply_depositor_metadata(@login_user.email)
        generic_file.save

        delete :destroy, params: { object_id: @object.alternate_id, id: generic_file.alternate_id }

        expect(flash[:error]).to be_present

        generic_file.destroy
      end
    end
  end

  describe 'collection is locked' do
    before(:each) do
      CollectionLock.create(collection_id: collection.alternate_id)
    end

    after(:each) do
      CollectionLock.where(collection_id: collection.alternate_id).delete_all
    end

    it 'should not allow asset creation' do
      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")

      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(flash[:error]).to be_present
    end

    it 'should not allow asset updates' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: generic_file.alternate_id, file: uploaded }

      expect(flash[:error]).to be_present

      generic_file.destroy
    end

    it 'should not allow asset deletion' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      delete :destroy, params: { object_id: object.alternate_id, id: generic_file.alternate_id }

      expect(flash[:error]).to be_present

      generic_file.destroy
    end
  end

  describe 'new' do
    it 'renders successfully' do
      get :new, params: { object_id: object.alternate_id }

      expect(response).to be_successful
      expect(assigns(:document)).to be_present
    end

    it 'denies a signed-in user without edit permissions' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      get :new, params: { object_id: object.alternate_id }

      expect(response.status).to eq(401)

      plain_user.destroy
    end
  end

  describe 'index' do
    it 'renders successfully with the object\'s assets and status' do
      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      get :index, params: { object_id: object.alternate_id }

      expect(response).to be_successful
      expect(assigns(:assets)).to be_present
      expect(assigns(:status)).to be_present

      generic_file.destroy
    end

    it 'denies a signed-in user without edit permissions' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      get :index, params: { object_id: object.alternate_id }

      expect(response.status).to eq(401)

      plain_user.destroy
    end

    it 'denies an anonymous user (authentication is required for index)' do
      sign_out login_user

      get :index, params: { object_id: object.alternate_id }

      expect(response).to_not be_successful
    end
  end

  describe 'show' do
    let(:generic_file) do
      DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint).tap do |gf|
        gf.digital_object = object
        gf.apply_depositor_metadata(login_user.email)
        gf.save
      end
    end

    after(:each) { generic_file.destroy if DRI::Identifier.object_exists?(generic_file.alternate_id) }

    it 'renders successfully for html requests' do
      get :show, params: { object_id: object.alternate_id, id: generic_file.alternate_id }

      expect(response).to be_successful
    end

    it 'renders the generic file as json' do
      get :show, params: { object_id: object.alternate_id, id: generic_file.alternate_id, format: :json }

      expect(response).to be_successful
    end

    it 'denies a non-editor viewing an unpublished object with no master file access' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      get :show, params: { object_id: object.alternate_id, id: generic_file.alternate_id }

      expect(response.status).to eq(401)

      plain_user.destroy
    end
  end

  describe 'download additional validations' do
    it 'returns not found when the file does not exist on disk' do
      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      get :download, params: { id: generic_file.alternate_id, object_id: object.alternate_id }

      expect(response.status).to eq(404)

      generic_file.destroy
    end

    it 'supports partial (range) requests' do
      object.master_file_access = 'public'
      object.edit_users_string = login_user.email
      object.read_users_string = login_user.email
      object.save
      object.reload

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      options = { mime_type: "audio/mp3", file_name: "SAMPLEA.mp3" }

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      request.headers['range'] = 'bytes=0-9'
      get :download, params: { id: file_id, object_id: object.alternate_id, type: 'masterfile' }

      expect(response.status).to eq(206)
      expect(response.headers['Content-Range']).to be_present
      expect(response.headers['Content-Length']).to eq('10')

      generic_file.destroy
    end
  end

  describe 'upload' do
    let(:storage) { double('storage') }
    let(:expected_bucket) { "users.#{::Mail::Address.new(login_user.email).local}.uploads" }
 
    before do
      allow(Storage::S3Interface).to receive(:new).and_return(storage)
    
      allow(JSON).to receive(:parse).and_call_original
      allow(JSON).to receive(:parse).with(instance_of(String)).and_return(
        'filename' => 'test.mp3', 'contentType' => 'audio/mp3'
      )
    end
 
    it 'creates a bucket named after the current user and requests a presigned PUT url for the given file' do
      expect(storage).to receive(:create_upload_bucket).with(expected_bucket).and_return(true)
      expect(storage).to receive(:put_url).with(expected_bucket, 'test.mp3', 'audio/mp3', true)
                                           .and_return('https://s3.example.com/presigned-url')
 
      post :upload, params: { object_id: object.alternate_id }
 
      expect(response).to be_successful
      json = response.parsed_body
      expect(json['url']).to eq('https://s3.example.com/presigned-url')
      expect(json['method']).to eq('PUT')
      expect(json['headers']).to eq('content-type' => 'audio/mp3')
    end
 
    it 'returns an internal server error when the upload bucket cannot be created, without requesting a url' do
      expect(storage).to receive(:create_upload_bucket).with(expected_bucket).and_return(false)
      expect(storage).to_not receive(:put_url)
 
      post :upload, params: { object_id: object.alternate_id }
 
      expect(response.status).to eq(500)
    end
  end

  describe 'create/update common validations' do
    it 'redirects with a notice when no file is given on create' do
      post :create, params: { object_id: object.alternate_id }

      expect(flash[:notice]).to be_present
    end

    it 'redirects with a notice when no file is given on update' do
      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      put :update, params: { object_id: object.alternate_id, id: generic_file.alternate_id }

      expect(flash[:notice]).to be_present

      generic_file.destroy
    end

    it 'renders a json response on create' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded, format: :json }

      expect(response).to be_successful
      json = response.parsed_body
      expect(json['messages']).to be_present
    end

    it 'renders a json response on update' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      put :update, params: { object_id: object.alternate_id, id: generic_file.alternate_id, file: uploaded, format: :json }

      expect(response).to be_successful
      json = response.parsed_body
      expect(json).to have_key('checksum')

      generic_file.destroy
    end

    it 'denies a signed-in user without edit permissions on create' do
      sign_out login_user
      plain_user = FactoryBot.create(:user)
      sign_in plain_user

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      post :create, params: { object_id: object.alternate_id, file: uploaded }

      expect(response.status).to eq(401)

      plain_user.destroy
    end
  end

  describe 'destroy additional validations' do
    it 'denies deleting an asset from a published object for a non-admin' do
      sign_out login_user
      manager = FactoryBot.create(:collection_manager)
      object.manager_users_string = manager.email
      object.status = 'published'
      object.save
      sign_in manager

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.save

      delete :destroy, params: { object_id: object.alternate_id, id: generic_file.alternate_id }

      expect(response.status).to eq(401)

      generic_file.destroy
      manager.destroy
    end
  end
end