require 'rails_helper'

describe 'ProcessBatchIngest' do

  before(:each) do
    allow_any_instance_of(DRI::GenericFile).to receive(:apply_depositor_metadata)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)
    @collection = FactoryBot.create(:collection)
  end

  after(:each) do
    @collection.destroy
    @login_user.delete if @login_user
  end

   context "ingest object" do

    let(:master_file) { DRIBatchIngest::MasterFile.create }
    let(:asset_master_file) { DRIBatchIngest::MasterFile.create }

    it "should create an object from metadata and asset" do
      tmp_download_dir = Dir.mktmpdir
      tmp_storage_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir
      allow(Settings.ingest).to receive(:storage_root).and_return(tmp_storage_dir)

      tmp_file = Tempfile.new(['metadata', '.xml'], tmp_storage_dir)
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)

      asset_tmp_file = Tempfile.new(['sample_image', '.jpeg'], tmp_storage_dir)
      FileUtils.cp(file_fixture('sample_image.jpeg'), asset_tmp_file.path)

      ingest_message = {}
      ingest_message['collection'] = @collection.alternate_id
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
      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      ProcessBatchIngest.perform(@login_user.id, @collection.alternate_id, ingest_message.to_json)

      master_file.reload
      asset_master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
      expect(asset_master_file.status_code).to eq 'COMPLETED'

      FileUtils.remove_dir(tmp_download_dir, force: true)
      FileUtils.remove_dir(tmp_storage_dir, force: true)
    end

    it 'does not leave assets COMPLETED when preservation fails' do
      tmp_download_dir = Dir.mktmpdir
      tmp_storage_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir
      allow(Settings.ingest).to receive(:storage_root).and_return(tmp_storage_dir)

      tmp_file = Tempfile.new(['metadata', '.xml'], tmp_storage_dir)
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)

      asset_tmp_file = Tempfile.new(['sample_image', '.jpeg'], tmp_storage_dir)
      FileUtils.cp(file_fixture('sample_image.jpeg'), asset_tmp_file.path)

      ingest_message = {}
      ingest_message['collection'] = @collection.alternate_id
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
      allow_any_instance_of(Preservation::Preservator).to receive(:preserve_assets).and_raise(StandardError, 'moab failed')

     
      expect { ProcessBatchIngest.perform(@login_user.id, @collection.alternate_id, ingest_message.to_json) }.to raise_error(StandardError, 'moab failed')

      master_file = DRIBatchIngest::MasterFile.find(asset_master_file.id)
      expect(master_file.status_code).to eq('FAILED')
      expect(master_file.file_location).to start_with('error: StandardError: moab failed')
    end
  end

  context "ingest metadata" do

    let(:master_file) { DRIBatchIngest::MasterFile.create }

    it "should create an object from metadata XML" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      expect(rc).to eq 0
      expect(object.valid?).to be true
      expect(object.persisted?).to be true
    end

     it "should create add an object to the correct collection" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      expect(rc).to eq 0
      object.reload
      expect(object.valid?).to be true
      expect(object.persisted?).to be true
      expect(object.governing_collection.alternate_id).to eq @collection.alternate_id
    end

  end

  context "ingest asset" do

    let(:master_file) { DRIBatchIngest::MasterFile.create }
    let(:object) { FactoryBot.create(:image) }

    it "should create an asset from file" do
      tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(file_fixture('sample_image.jpeg'), tmp_file.path)
      assets = [{ master_file_id: master_file.id, path: tmp_file.path }]
      object.increment_version
      object.save

      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
    end

    it "should create a preservation asset from file" do
      tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(file_fixture('sample_image.jpeg'), tmp_file.path)
      assets = [{ label: 'preservation', master_file_id: master_file.id, path: tmp_file.path }]
      object.increment_version
      object.save

      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).once
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      master_file.reload
      id = master_file.file_location.split('/').last

      expect(DRI::GenericFile.find_by_alternate_id(id).preservation?).to be true
      expect(master_file.status_code).to eq 'COMPLETED'
    end

    it "should not error if preservation asset and asset are the same file" do
      tmp_file = Tempfile.new(['sample_image', '.jpeg'])
      FileUtils.cp(file_fixture('sample_image.jpeg'), tmp_file.path)
      pres_master_file = DRIBatchIngest::MasterFile.create
      assets = [{ master_file_id: master_file.id, path: tmp_file.path }, { label: 'preservation', master_file_id: pres_master_file.id, path: tmp_file.path }]
      object.increment_version
      object.save

      expect(DRI.queue).to receive(:push).with(an_instance_of(CharacterizeJob)).twice
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      pres_master_file.reload
      id = pres_master_file.file_location.split('/').last

      expect(DRI::GenericFile.find_by_alternate_id(id).preservation?).to be true
      expect(pres_master_file.status_code).to eq 'COMPLETED'
      expect(aip_valid?(object.alternate_id, 2)).to be true
    end

    it 'keeps asset and preservation copies with the same name apart' do
      Dir.mktmpdir do |storage|
        Dir.mktmpdir do |downloads|
          allow(Settings.ingest).to receive(:storage_root).and_return(storage)
          files = %w[data preservation].each_with_index.map do |dir, i|
            FileUtils.mkdir_p(File.join(storage, 'u@x.ie/files', dir, 'obj1'))
            File.write(File.join(storage, 'u@x.ie/files', dir, 'obj1/scan.tif'), dir)
            { 'id' => i, 'label' => (dir == 'data' ? 'asset' : 'preservation'),
              'download_spec' => { 'url' => "file://#{storage}/u@x.ie/files/#{dir}/obj1/scan.tif", 'file_name' => 'scan.tif' } }
          end

          results = ProcessBatchIngest.retrieve_files(downloads, files)

          expect(results.map { |r| File.read(r[:path]) }).to eq(%w[data preservation])
        end
      end
    end
  end

  context "ingest errors" do

    let(:master_file) { DRIBatchIngest::MasterFile.create }
    let(:asset_master_file) { DRIBatchIngest::MasterFile.create }

    it "should rescue errors saving metadata" do
      allow_any_instance_of(DRI::DigitalObject).to receive(:save).and_raise(ActiveRecord::RecordNotSaved)

      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object.persisted?).to be false
      expect(master_file.status_code).to eq 'FAILED'
    end

    it "should rollback object save if Solr error saving metadata", truncate: true do
      allow_any_instance_of(DRI::DigitalObject).to receive(:update_index).and_return(false)

      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object.persisted?).to be false
      expect(master_file.status_code).to eq 'FAILED'
    end

    it "should rescue errors saving metadata with missing required fields" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('metadata_no_rights.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object.persisted?).to be false
      expect(master_file.status_code).to eq 'FAILED'
    end

    it "should rescue errors saving metadata with invalid xml" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(file_fixture('invalid_xml_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      rc, object = ProcessBatchIngest.ingest_metadata(@collection.alternate_id, @login_user, metadata)

      master_file.reload

      expect(rc).to eq -1
      expect(object).to be_nil
      expect(master_file.status_code).to eq 'FAILED'
      expect(master_file.file_location).to start_with("error: invalid metadata")
    end

    it "should rescue errors if metadata file not found" do
      tmp_download_dir = Dir.mktmpdir
      tmp_storage_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir
      allow(Settings.ingest).to receive(:storage_root).and_return(tmp_storage_dir)

      allow(FileUtils).to receive(:cp).and_raise(Errno::ENOENT)
      tmp_file = Tempfile.new(['metadata', '.xml'], tmp_storage_dir)

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

      ProcessBatchIngest.perform(@login_user.id, @collection.alternate_id, ingest_message.to_json)

      master_file.reload
      expect(master_file.status_code).to eq 'FAILED'

      FileUtils.remove_dir(tmp_download_dir, force: true)
      FileUtils.remove_dir(tmp_storage_dir, force: true)
    end

    it "should rescue errors if asset file not found" do
      tmp_download_dir = Dir.mktmpdir
      tmp_storage_dir = Dir.mktmpdir
      Settings.downloads.directory = tmp_download_dir
      allow(Settings.ingest).to receive(:storage_root).and_return(tmp_storage_dir)

      tmp_file = Tempfile.new(['metadata', '.xml'], tmp_storage_dir)
      FileUtils.cp(file_fixture('valid_metadata.xml'), tmp_file.path)

      asset_tmp_file = Tempfile.new(['sample_image', '.jpeg'], tmp_storage_dir)
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

      ProcessBatchIngest.perform(@login_user.id, @collection.alternate_id, ingest_message.to_json)

      master_file.reload
      asset_master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
      expect(asset_master_file.status_code).to eq 'FAILED'

      FileUtils.remove_dir(tmp_download_dir, force: true)
      FileUtils.remove_dir(tmp_storage_dir, force: true)
    end

    describe '.perform when an unexpected error is raised' do
      let(:user) { FactoryBot.create(:collection_manager) }
      let(:ingest) { DRIBatchIngest::UserIngest.create!(user: user) }
      let(:batch) do
        DRIBatchIngest::IngestBatch.create!(user_ingest: ingest, collection_id: 'col1', email: user.email)
      end
      let(:media_object) { DRIBatchIngest::MediaObject.create!(ingest_batch: batch, collection: 'col1') }
      let(:downloads) { Dir.mktmpdir }

      let!(:metadata_file) do
        DRIBatchIngest::MasterFile.create!(
          media_object: media_object, status_code: 'PENDING', metadata: true,
          download_spec: { url: 'file:///x/object.xml', file_name: 'object.xml', file_size: 1 }.to_json
        )
      end
      let!(:asset_file) do
        DRIBatchIngest::MasterFile.create!(
          media_object: media_object, status_code: 'PENDING',
          download_spec: { url: 'file:///x/a.jpg', file_name: 'a.jpg', file_size: 1 }.to_json
        )
      end

      let(:message) { DRIBatchIngest::ProcessBatch.process_media_object(media_object, 'col1').to_json }

      before do
        allow(Settings.downloads).to receive(:directory).and_return(downloads)
        allow(ProcessBatchIngest).to receive(:retrieve_files).and_raise(StandardError, 'boom')
      end

      after { FileUtils.remove_entry(downloads) }

      it 'marks unfinished master files FAILED and re-raises' do
        expect { ProcessBatchIngest.perform(user.id, 'col1', message) }.to raise_error(StandardError, 'boom')

        expect([metadata_file, asset_file].map { |f| f.reload.status_code }).to all(eq('FAILED'))
        expect(asset_file.reload.file_location).to start_with('error: StandardError: boom')
      end

      it 'leaves master files that already completed alone' do
        asset_file.update!(status_code: 'COMPLETED', file_location: 'done')

        expect { ProcessBatchIngest.perform(user.id, 'col1', message) }.to raise_error(StandardError, 'boom')

        expect(asset_file.reload.status_code).to eq('COMPLETED')
        expect(asset_file.file_location).to eq('done')
        expect(metadata_file.reload.status_code).to eq('FAILED')
      end

      it 'removes its download directory' do
        expect { ProcessBatchIngest.perform(user.id, 'col1', message) }.to raise_error(StandardError, 'boom')

        expect(Dir.children(File.join(downloads, 'col1'))).to be_empty
      end
    end
  end
end
