require 'rails_helper'

describe 'ProcessBatchIngest' do

  before do
    allow(ProcessBatchIngest).to receive(:current_user).and_return(@login_user)
    allow(ProcessBatchIngest).to receive(:params).and_return({preservation: 'false'})
    allow_any_instance_of(DRI::GenericFile).to receive(:apply_depositor_metadata)
    allow_any_instance_of(DRI::Asset::Actor).to receive(:create_external_content)
  end

  before(:each) do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @login_user = FactoryBot.create(:collection_manager)
    @collection = FactoryBot.create(:collection)
  end

  after(:each) do
    @login_user.delete
  end

  context "ingest metadata" do

    let(:master_file) { DriBatchIngest::MasterFile.create }

    it "should create an object from metadata XML" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)
      metadata = { master_file_id: master_file.id, path: tmp_file.path }
      object = ProcessBatchIngest.ingest_metadata(@collection, @login_user, metadata)

      expect(object.valid?).to be true
      expect(object.persisted?).to be true
    end

  end

  context "ingest asset" do

    let(:master_file) { DriBatchIngest::MasterFile.create }
    let(:object) { FactoryBot.create(:image) }

    it "should create an asset from file" do
      tmp_file = Tempfile.new(['metadata', '.xml'])
      FileUtils.cp(File.join(fixture_path, 'valid_metadata.xml'), tmp_file.path)
      assets = [{ master_file_id: master_file.id, path: tmp_file.path }]
      ProcessBatchIngest.ingest_assets(@login_user, object, assets)

      master_file.reload
      expect(master_file.status_code).to eq 'COMPLETED'
    end

  end

end
