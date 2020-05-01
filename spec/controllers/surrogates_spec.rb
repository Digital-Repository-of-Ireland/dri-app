require 'rails_helper'

describe SurrogatesController do
  include Devise::Test::ControllerHelpers

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:admin)
    sign_in @login_user

    @collection = FactoryBot.create(:collection)
    @object = FactoryBot.create(:sound)

    @collection.governed_items << @object
    @collection.save

    @gf = DRI::GenericFile.new
    @gf.apply_depositor_metadata(@login_user)
    @gf.digital_object = @object
    @gf.save
  end

  after(:each) do
    @collection.destroy
    @login_user.delete
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, params: { id: @collection.noid }
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, params: { id: @object.noid }
    end

    it 'should update multiple files' do
      @gf2 = DRI::GenericFile.new
      @gf2.apply_depositor_metadata(@login_user)
      @gf2.digital_object = @object
      @gf2.save

      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, params: { id: @object.noid }

      @gf2.destroy
    end

  end

  describe 'show' do

    it 'should return 404 for a surrogate that does not exist' do
      generic_file = DRI::GenericFile.new(noid: Noid::Rails::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.save

      get :show, params: { object_id: @object.noid, id: generic_file.noid, surrogate: 'thumbnail' }
      expect(response.status).to eq(404)
    end

  end

  describe 'download' do

    it "should be possible to download the surrogate" do
      allow_any_instance_of(GenericFileContent).to receive(:external_content)

      @object.master_file_access = 'public'
      @object.edit_users_string = @login_user.email
      @object.read_users_string = @login_user.email
      @object.save
      @object.reload

      generic_file = DRI::GenericFile.new(noid: Noid::Rails::Service.new.mint)
      generic_file.batch = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.mime_type = "audio/mp3"
      file = LocalFile.new(fedora_id: generic_file.noid, ds_id: "content")
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"
      options[:batch_id] = @object.noid

      uploaded = Rack::Test::UploadedFile.new(File.join(fixture_path, "SAMPLEA.mp3"), "audio/mp3")
      file.add_file uploaded, options
      file.save
      generic_file.save
      file_id = generic_file.noid

      storage = StorageService.new
      storage.create_bucket(@object.noid)
      storage.store_surrogate(@object.noid, File.join(fixture_path, "SAMPLEA.mp3"), "#{generic_file.id}_mp3.mp3")

      get :download, params: { id: file_id, object_id: @object.noid, type: 'surrogate' }
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mpeg')
    end
  end
end
