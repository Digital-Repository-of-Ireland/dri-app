require 'rails_helper'

describe ApiController do
  include Devise::Test::ControllerHelpers
  include Warden::Test::Helpers

  let(:tmp_upload_dir) { Dir.mktmpdir }
  let(:tmp_assets_dir) { Dir.mktmpdir }
  let(:login_user) { FactoryBot.create(:admin) }

  let(:collection) { FactoryBot.create(:collection) }
  let(:object) { FactoryBot.create(:sound) }

  before(:each) do
    Settings.dri.uploads = tmp_upload_dir
    Settings.dri.files = tmp_assets_dir

    sign_in login_user

    object[:status] = "draft"
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

  describe 'objects' do
    before(:each) do
      object.status = 'published'
      object.save
    end

    it 'should assign valid JSON to @list' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :objects, params: { objects: [{ 'pid' => object.id }] }
      list = controller.instance_variable_get(:@list)
      expect { JSON.parse(list.to_json) }.not_to raise_error
    end

    it 'should contain the metadata fields' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :objects, params: { objects: [{ 'pid' => object.id }] }
      list = controller.instance_variable_get(:@list)
      json = JSON.parse(list.to_json)

      expect(json.first['metadata']['title']).to eq(object.title)
      expect(json.first['metadata']['description']).to eq(object.description)
      expect(json.first['metadata']['contributor']).to eq(object.contributor)
    end

    it 'should only return the requested fields' do
      request.env["HTTP_ACCEPT"] = 'application/json'

      post :objects, params: { objects: [{ 'pid' => object.id }], metadata: ['title', 'description'] }
      list = controller.instance_variable_get(:@list)
      json = JSON.parse(list.to_json)

      expect(json.first['metadata']['title']).to eq(object.title)
      expect(json.first['metadata']['description']).to eq(object.description)
      expect(json.first['metadata']['contributor']).to be nil
    end

    it 'should include assets and surrogates' do
      gf = DRI::GenericFile.new
      gf.apply_depositor_metadata(login_user)
      gf.batch = object
      gf.save

      storage = StorageService.new
      storage.create_bucket(object.id)
      storage.store_surrogate(object.id, File.join(fixture_path, "SAMPLEA.mp3"), "#{gf.id}_mp3.mp3")

      request.env["HTTP_ACCEPT"] = 'application/json'
      post :objects, params: { objects: [{ 'pid' => object.id }] }
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].first).to include('masterfile')
      expect(list.first['files'].first).to include('mp3')
    end

    it 'should return draft objects if I have permissions' do
      sign_out login_user
      user = FactoryBot.create(:user)
      sign_in user

      object.status = 'draft'
      object.edit_users_string = user.email
      object.save
      object.reload

      request.env["HTTP_ACCEPT"] = 'application/json'

      post :objects, params: { objects: [{ 'pid' => object.id }] }
      expect(response.status).to eq(200)

      user.destroy
    end

    it 'should not return draft objects if I do not have permissions' do
      object.status = 'draft'
      object.edit_users_string = login_user.email
      object.save
      object.reload

      sign_out login_user
      user = FactoryBot.create(:user)
      sign_in user

      request.env["HTTP_ACCEPT"] = 'application/json'

      post :objects, params: { objects: [{ 'pid' => object.id }] }
      expect(response.status).to eq(404)

      user.destroy
    end
  end

  describe 'list_assets' do

    before(:each) do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      object.master_file_access = 'public'
      object.edit_users_string = login_user.email
      object.read_users_string = login_user.email
      object.save
      object.reload

      generic_file = DRI::GenericFile.new(id: Noid::Rails::Service.new.mint)
      generic_file.batch = object
      generic_file.apply_depositor_metadata(login_user.email)
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.id

      storage = StorageService.new
      storage.create_bucket(object.id)
      storage.store_surrogate(object.id, File.join(fixture_path, "SAMPLEA.mp3"), "#{generic_file.id}_mp3.mp3")
    end

    it "should return a list of asset information" do
      request.env["HTTP_ACCEPT"] = 'application/json'
      post :assets, params: { objects: [ { "pid" => "#{object.id}" } ] }
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].first).to include('masterfile')
      expect(list.first['files'].first).to include('mp3')
    end

    it "should not return preservation only files" do
      generic_file = DRI::GenericFile.new(id: Noid::Rails::Service.new.mint)
      generic_file.batch = object
      generic_file.apply_depositor_metadata(login_user.email)
      generic_file.preservation_only = 'true'
      file = LocalFile.new(fedora_id: generic_file.id, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = object.id

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save

      request.env["HTTP_ACCEPT"] = 'application/json'
      post :assets, params: { objects: [ { "pid" => "#{object.id}" } ] }
      list = controller.instance_variable_get(:@list)

      expect(list.first).to include('files')
      expect(list.first['files'].count).to be 1
    end

  end
end
