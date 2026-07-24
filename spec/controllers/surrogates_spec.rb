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

  describe 'show' do

    it 'should return 404 for a surrogate that does not exist' do
      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.save

      get :show, params: { object_id: @object.alternate_id, id: generic_file.alternate_id, surrogate: 'thumbnail' }
      expect(response.status).to eq(404)
      generic_file.destroy
    end

    it 'returns not found when no surrogate type is given at all' do
      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.save

      get :show, params: { object_id: @object.alternate_id, id: generic_file.alternate_id }
      expect(response.status).to eq(404)

      generic_file.destroy
    end

    it 'streams an existing surrogate successfully' do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.mime_type = "audio/mp3"
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save

      storage = StorageService.new
      storage.create_bucket(@object.alternate_id)
      storage.store_surrogate(@object.alternate_id, file_fixture("SAMPLEA.mp3"), "#{generic_file.alternate_id}_mp3.mp3")

      # NOTE: mirrors the surrogate-name pattern proven in the 'download'
      # spec below (bare 'mp3', matching what #surrogate_type_name would
      # derive for an audio file), on the assumption that surrogate
      # lookup matches by prefix regardless of the stored key's own
      # extension.
      get :show, params: { object_id: @object.alternate_id, id: generic_file.alternate_id, surrogate: 'mp3' }

      expect(response.status).to eq(302)

      generic_file.destroy
    end

  end

  describe 'download' do

    it "should be possible to download the surrogate" do
      allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)

      @object.master_file_access = 'public'
      @object.edit_users_string = @login_user.email
      @object.read_users_string = @login_user.email
      @object.save
      @object.reload

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.mime_type = "audio/mp3"
      options = {}
      options[:mime_type] = "audio/mp3"
      options[:file_name] = "SAMPLEA.mp3"

      uploaded = Rack::Test::UploadedFile.new(file_fixture("SAMPLEA.mp3"), "audio/mp3")
      generic_file.add_file uploaded, options
      generic_file.save
      file_id = generic_file.alternate_id

      storage = StorageService.new
      storage.create_bucket(@object.alternate_id)
      storage.store_surrogate(@object.alternate_id, file_fixture("SAMPLEA.mp3"), "#{generic_file.alternate_id}_mp3.mp3")

      get :download, params: { id: file_id, object_id: @object.alternate_id, type: 'surrogate' }
      expect(response.status).to eq(200)
      expect(response.header['Content-Type']).to eq('audio/mpeg')
      generic_file.destroy
    end

    it "renders a 404 message when the generic file can't be found" do
      get :download, params: { id: 'nonexistent-id-zzz', object_id: @object.alternate_id }

      expect(response.status).to eq(404)
    end
  end

  describe 'index' do

    it 'denies an anonymous user (authentication is required for index)' do
      sign_out @login_user

      get :index, params: { id: @object.alternate_id, format: :json }

      expect(response.status).to eq(401)
    end

    it 'completes successfully for an authorised user' do
      get :index, params: { id: @object.alternate_id, format: :json }

      expect(response).to be_successful
    end
  end

  describe 'update' do

    it 'should update a collections surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, params: { id: @collection.alternate_id }
    end

    it 'should update an objects surrogates' do
      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      put :update, params: { id: @object.alternate_id }
    end

    it 'should update multiple files' do
      @gf2 = DRI::GenericFile.new
      @gf2.apply_depositor_metadata(@login_user)
      @gf2.digital_object = @object
      @gf2.save

      request.env["HTTP_REFERER"] = "/"
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).twice
      put :update, params: { id: @object.alternate_id }

      @gf2.destroy
    end

    it 'returns not found for an id that does not exist' do
      request.env["HTTP_REFERER"] = "/"

      put :update, params: { id: 'nonexistent-id-zzz' }

      expect(response.status).to eq(404)
    end

    it 'responds successfully to a json request' do
      request.env["HTTP_REFERER"] = "/"

      put :update, params: { id: @object.alternate_id, format: :json }

      expect(response).to be_successful
    end

    it 'flashes an alert instead of a notice when queuing a job fails' do
      allow(DRI.queue).to receive(:push).and_raise(StandardError, 'queue unavailable')
      request.env["HTTP_REFERER"] = "/"

      put :update, params: { id: @object.alternate_id }

      expect(flash[:alert]).to be_present
      expect(flash[:notice]).to be_nil
    end

    it 'blocks updates when the app is in read-only mode' do
      Settings.add_source!(file_fixture("settings-ro.yml").to_s)
      Settings.reload!

      request.env["HTTP_REFERER"] = "/"
      put :update, params: { id: @object.alternate_id }

      expect(flash[:error]).to be_present

      Settings.reload_from_files(Config.setting_files(File.join(Rails.root, 'config'), Rails.env))
    end

  end

  describe 'anonymous access' do
    before(:each) do
      @object.discover_groups_string = 'public'
      @object.read_groups_string = 'public'
      @object.status = 'published'
      @object.save
      @collection.status = 'published'
      @collection.save
    end

    it 'allows anonymous access to show for a public object (no sign-in required)' do
      sign_out @login_user

      generic_file = DRI::GenericFile.new(alternate_id: Noid::Rails::Service.new.mint)
      generic_file.digital_object = @object
      generic_file.apply_depositor_metadata(@login_user.email)
      generic_file.save

      get :show, params: { object_id: @object.alternate_id, id: generic_file.alternate_id, surrogate: 'thumbnail' }

      # Not found (no such surrogate stored) rather than blocked by an
      # auth/permission failure - proving show doesn't require sign-in
      # the way index does.
      expect(response.status).to eq(404)

      generic_file.destroy
    end
  end
end