require 'rails_helper'

describe DoiSyncService do
  include Preservation::PreservationHelpers

  let(:doi_config) do
    OpenStruct.new(
      username:  'user',
      password:  'password',
      prefix:    '10.5072',
      base_url:  'http://repository.dri.ie',
      publisher: 'Digital Repository of Ireland'
    )
  end

  before do
    @tmp_assets_dir = Dir.mktmpdir
    Settings.dri.files = @tmp_assets_dir

    @collection = FactoryBot.create(:collection)
    @object     = FactoryBot.create(:sound)
    @collection.governed_items << @object
    @object.reload
  end

  after do
    @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  # ------------------------------------------------------------------ #call

  describe '#call' do
    context 'when DOI is disabled' do
      before { Settings.doi.enable = false }

      it 'does nothing' do
        expect(DataciteDoi).not_to receive(:find_by)
        DoiSyncService.new(@object).call
      end
    end

    context 'when DOI is enabled' do
      before do
        stub_const('DoiConfig', doi_config)
        Settings.doi.enable = true
      end

      after { Settings.doi.enable = false }

      it 'does nothing when no DOI record exists' do
        expect(Resque).not_to receive(:enqueue)
        DoiSyncService.new(@object).call
      end

      context 'when a DOI record exists' do
        before do
          @doi = DataciteDoi.create(object_id: @object.alternate_id)
          allow(Resque).to receive(:enqueue)
        end
        after  { DataciteDoi.where(object_id: @object.alternate_id).destroy_all }

        it 'enqueues UpdateDoiJob when non-mandatory fields change' do
          allow(@doi).to receive(:changed?).and_return(true)
          allow(@doi).to receive(:mandatory_update?).and_return(false)
          allow(DataciteDoi).to receive(:find_by).and_return(@doi)

          expect(Resque).to receive(:enqueue).with(UpdateDoiJob, @doi.id)
          DoiSyncService.new(@object).call
        end

        it 'mints a new DOI when mandatory fields change on a published object' do
          @object.status = 'published'
          @object.save

          allow(@doi).to receive(:changed?).and_return(true)
          allow(@doi).to receive(:mandatory_update?).and_return(true)
          allow(DataciteDoi).to receive(:find_by).and_return(@doi)

          expect {
            DoiSyncService.new(@object).call
          }.to change { DataciteDoi.count }.by(1)
        end

        it 'enqueues MintDoiJob for the new DOI when mandatory fields change' do
          @object.status = 'published'
          @object.save

          allow(@doi).to receive(:changed?).and_return(true)
          allow(@doi).to receive(:mandatory_update?).and_return(true)
          allow(DataciteDoi).to receive(:find_by).and_return(@doi)

          expect(Resque).to receive(:enqueue).with(MintDoiJob, anything)
          DoiSyncService.new(@object).call
        end

        it 'does not mint a new DOI when mandatory fields change but object is not published' do
          @object.status = 'draft'
          @object.save

          allow(@doi).to receive(:changed?).and_return(true)
          allow(@doi).to receive(:mandatory_update?).and_return(true)
          allow(DataciteDoi).to receive(:find_by).and_return(@doi)

          expect {
            DoiSyncService.new(@object).call
          }.not_to change { DataciteDoi.count }
        end
      end
    end
  end

  # ------------------------------------------------------------ #sync_metadata

  describe '#sync_metadata' do
    context 'when DOI is disabled' do
      before { Settings.doi.enable = false }

      it 'returns nil' do
        expect(DoiSyncService.new(@object).sync_metadata).to be_nil
      end
    end

    context 'when DOI is enabled but no record exists' do
      before do
        stub_const('DoiConfig', doi_config)
        Settings.doi.enable = true
      end

      after { Settings.doi.enable = false }

      it 'returns nil' do
        expect(DoiSyncService.new(@object).sync_metadata).to be_nil
      end
    end

    context 'when DOI is enabled and a record exists' do
      before do
        stub_const('DoiConfig', doi_config)
        Settings.doi.enable = true
        @doi = DataciteDoi.create(object_id: @object.alternate_id)
      end

      after do
        DataciteDoi.where(object_id: @object.alternate_id).destroy_all
        Settings.doi.enable = false
      end

      it 'returns the doi record' do
        result = DoiSyncService.new(@object).sync_metadata
        expect(result).to eq(@doi)
      end

      it 'calls update_metadata on the doi' do
        expect(@doi).to receive(:update_metadata)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)
        DoiSyncService.new(@object).sync_metadata
      end
    end
  end

  # ----------------------------------------------- #create_new_doi_if_required

  describe '#create_new_doi_if_required' do
    before do
      stub_const('DoiConfig', doi_config)
      Settings.doi.enable = true
      @doi = DataciteDoi.create(object_id: @object.alternate_id)
      @object.status = 'published'
      @object.save
    end

    after do
      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'creates a new DOI when mandatory fields have changed on a published object' do
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(true)

      expect {
        DoiSyncService.new(@object).create_new_doi_if_required(@doi)
      }.to change { DataciteDoi.count }.by(1)
    end

    it 'does not create a new DOI when fields have not changed' do
      allow(@doi).to receive(:changed?).and_return(false)

      expect {
        DoiSyncService.new(@object).create_new_doi_if_required(@doi)
      }.not_to change { DataciteDoi.count }
    end

    it 'does not create a new DOI when changed fields are not mandatory' do
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(false)

      expect {
        DoiSyncService.new(@object).create_new_doi_if_required(@doi)
      }.not_to change { DataciteDoi.count }
    end
  end

  # ----------------------------------------------------------- #enqueue_job

  describe '#enqueue_job' do
    let(:service) { DoiSyncService.new(@object) }

    before do
      stub_const('DoiConfig', doi_config)
      Settings.doi.enable = true
      @doi = DataciteDoi.create(object_id: @object.alternate_id)
    end

    after do
      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'enqueues MintDoiJob when a new DOI was created in this service instance' do
      @object.status = 'published'
      @object.save
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(true)

      service.create_new_doi_if_required(@doi)
      expect(Resque).to receive(:enqueue).with(MintDoiJob, anything)
      service.enqueue_job(@doi)
    end

    it 'enqueues UpdateDoiJob when the existing DOI record has changed' do
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(false)

      expect(Resque).to receive(:enqueue).with(UpdateDoiJob, @doi.id)
      service.enqueue_job(@doi)
    end

    it 'enqueues nothing when the DOI record has not changed' do
      allow(@doi).to receive(:changed?).and_return(false)

      expect(Resque).not_to receive(:enqueue)
      service.enqueue_job(@doi)
    end

    it 'prefers MintDoiJob over UpdateDoiJob when a new DOI exists' do
      @object.status = 'published'
      @object.save
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(true)

      service.create_new_doi_if_required(@doi)

      expect(Resque).to receive(:enqueue).with(MintDoiJob, anything).once
      expect(Resque).not_to receive(:enqueue).with(UpdateDoiJob, anything)
      service.enqueue_job(@doi)
    end
  end
end