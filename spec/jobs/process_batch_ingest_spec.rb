require 'rails_helper'

describe 'ProcessBatchIngest' do

  before(:each) do
    allow_any_instance_of(DRI::GenericFile).to receive(:apply_depositor_metadata)
    allow_any_instance_of(GenericFileContent).to receive(:push_characterize_job)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)
    @collection = FactoryBot.create(:collection)
  end

  after(:each) do
    @login_user.delete if @login_user
  end

   context "ingest object" do

    let(:master_file) { DriBatchIngest::MasterFile.create }
    let(:asset_master_file) { DriBatchIngest::MasterFile.create }

    it "should create an object from metadata and asset" do
      tmp_download_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir

      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)

      asset_tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(File.join(fixture_path, 'sample_image.jpeg'), asset_tmp_file.path)

      ingest_message = {}
      ingest_message['collection'] = @collection_id
      ingest_message['media_object'] = 1
      ingest_message['metadata'] = {
        'id' => master_file.id,
        'label' => 'metadata',
        'download_spec' => {
        'url' => "file://#{tmp_file.path}",
        'file_name' => File.basename(tmp_file.path)
        }
      }
      ingest_message['files'] = [
        {
          'id' => asset_master_file.id,
          'label' => 'asset',
          'download_spec' => {
                  'url' => "file://#{asset_tmp_file.path}",
                  'file_name' => File.basename(asset_tmp_file.path)
                  }
        }
      ]

      ProcessBatchIngest.perform(@login_user.id, @collection.id, ingest_message.to_json)

      master_file.reload
      asset_master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
      expect(asset_master_file.status_code).to eq 'COMPLETED'

      FileUtils.remove_dir(tmp_download_dir, force: true)
    end

  end

  context "ingest metadata" do

    let(:master_file) { DriBatchIngest::MasterFile.create }

    it "should create an object from metadata XML" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.id, @login_user, metadata)

      expect(rc).to eq 0
      expect(object.valid?).to be true
      expect(object.persisted?).to be true
    end

     it "should create add an object to the correct collection" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.id, @login_user, metadata)

      expect(rc).to eq 0
      expect(object.valid?).to be true
      expect(object.persisted?).to be true
      expect(object.governing_collection.id).to eq @collection.id
    end

  end

  context "ingest asset" do

    let(:master_file) { DriBatchIngest::MasterFile.create }
    let(:object) { FactoryBot.create(:image) }

    it "should create an asset from file" do
      tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(File.join(fixture_path, 'sample_image.jpeg'), tmp_file.path)
      assets = [{ master_file_id: master_file.id, path: tmp_file.path }]
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
    end

    it "should create a preservation asset from file" do
      tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(File.join(fixture_path, 'sample_image.jpeg'), tmp_file.path)
      assets = [{ label: 'preservation', master_file_id: master_file.id, path: tmp_file.path }]
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      master_file.reload
      id = master_file.file_location.split('/').last

      expect(DRI::GenericFile.find(id).preservation?).to be true
      expect(master_file.status_code).to eq 'COMPLETED'
    end

  end

  context "ingest errors" do

    let(:master_file) { DriBatchIngest::MasterFile.create }
    let(:asset_master_file) { DriBatchIngest::MasterFile.create }

    it "should rescue errors saving metadata" do
      allow_any_instance_of(DRI::Noid::Service).to receive(:mint).and_raise(Ldp::HttpError)

      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object.persisted?).to be false
      expect(master_file.status_code).to eq 'FAILED'
    end

     it "should rescue errors saving metadata with missing required fields" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'metadata_no_rights.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object.persisted?).to be false
      expect(master_file.status_code).to eq 'FAILED'
    end

    it "should rescue errors saving metadata with invalid xml" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'invalid_xml_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object).to be_nil
      expect(master_file.status_code).to eq 'FAILED'
      expect(master_file.file_location).to start_with("error: invalid metadata")
    end

    it "should rescue errors if metadata file not found" do
      Settings.downloads.directory = Dir.mktmpdir

      allow_any_instance_of(BrowseEverything::Retriever).to receive(:retrieve).and_raise(Errno::ENOENT)
      tmp_file = Tempfile.new(['metadata', '.xml'])

      ingest_message = {}
      ingest_message['collection'] = @collection_id
      ingest_message['media_object'] = 1
      ingest_message['metadata'] = {
        'id' => master_file.id,
        'label' => 'metadata',
        'download_spec' => {
        'url' => "file://#{tmp_file.path}",
        'file_name' => File.basename(tmp_file.path)
        }
      }
      ingest_message['files'] = []

      ProcessBatchIngest.perform(@login_user.id, @collection.id, ingest_message.to_json)

      master_file.reload
      expect(master_file.status_code).to eq 'FAILED'
    end

    it "should rescue errors if asset file not found" do
      tmp_download_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir

      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)

      asset_tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.rm asset_tmp_file

      ingest_message = {}
      ingest_message['collection'] = @collection_id
      ingest_message['media_object'] = 1
      ingest_message['metadata'] = {
        'id' => master_file.id,
        'label' => 'metadata',
        'download_spec' => {
        'url' => "file://#{tmp_file.path}",
        'file_name' => File.basename(tmp_file.path)
        }
      }
      ingest_message['files'] = [
        {
          'id' => asset_master_file.id,
          'label' => 'asset',
          'download_spec' => {
                  'url' => "file://#{asset_tmp_file.path}",
                  'file_name' => File.basename(asset_tmp_file.path)
                  }
        }
      ]

      ProcessBatchIngest.perform(@login_user.id, @collection.id, ingest_message.to_json)

      master_file.reload
      asset_master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
      expect(asset_master_file.status_code).to eq 'FAILED'

      FileUtils.remove_dir(tmp_download_dir, force: true)
    end
  end
end
