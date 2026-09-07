require 'rails_helper'

describe MetadataUpdateService do
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

    @user       = FactoryBot.create(:admin)
    @collection = FactoryBot.create(:collection)
    @object     = FactoryBot.create(:sound)
    @collection.governed_items << @object
    @object.reload

    # Stub preservation by default — tested explicitly in the preservation group
    # below with a correctly versioned object. Most tests are not about MOAB behaviour
    # and the factory already writes v0001, so letting preserve run would always fail.
    allow_any_instance_of(Preservation::Preservator).to receive(:preserve)
  end

  after do
    @user.destroy
    @collection.destroy if DRI::Identifier.object_exists?(@collection.alternate_id)
    FileUtils.remove_dir(@tmp_assets_dir, force: true)
  end

  def service
    MetadataUpdateService.new(@object, @user)
  end

  # ----------------------------------------------------------- save and index

  describe 'save and index' do
    it 'persists changes to the object' do
      @object.title = ['A new title']
      service.call
      expect(@object.reload.title).to eq(['A new title'])
    end

    it 'sets index_needs_update to false before saving' do
      @object.index_needs_update = true
      service.call
      expect(@object.index_needs_update).to be false
    end

    it 'increments the object version before saving' do
      original_version = @object.object_version
      service.call
      expect(@object.reload.object_version).to be > original_version
    end

    it 'raises InternalError when the object fails to save' do
      allow(@object).to receive(:save).and_return(false)
      expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
    end

    it 'raises InternalError when indexing fails' do
      allow(@object).to receive(:update_index).and_return(false)
      expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
    end

    it 'raises InternalError on a Solr Http error' do
      request  = {}
      response = { status: 500, body: '', headers: {} }
      allow(@object).to receive(:update_index).and_raise(RSolr::Error::Http.new(request, response))
      expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
    end

    it 'rolls back the object save when indexing fails' do
      original_title = @object.title.dup
      @object.title  = ['Changed title']

      allow(@object).to receive(:update_index).and_return(false)

      expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
      expect(@object.reload.title).to eq(original_title)
    end
  end

  # ----------------------------------------------------------- preservation

  describe 'preservation' do
    before do
      allow_any_instance_of(Preservation::Preservator).to receive(:preserve).and_call_original
    end

    it 'writes a new preservation version after a successful save' do
      expect { service.call }.to change { aip_version(@object.alternate_id) }.by(1)
    end

    it 'does not write a new preservation version when the save fails' do
      allow(@object).to receive(:save).and_return(false)
      expect {
        expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
      }.not_to change { aip_version(@object.alternate_id) }
    end
  end

  # ---------------------------------------------------------- linked data

  describe 'linked data' do
    before { stub_const('AuthoritiesConfig', true) }

    it 'enqueues a LinkedDataJob when the object has geographical coverage' do
      @object.geographical_coverage = ['Dublin']
      @object.save

      expect(DRI.queue).to receive(:push).with(an_instance_of(LinkedDataJob))
      service.call
    end

    it 'enqueues a LinkedDataJob when the object has coverage' do
      @object.coverage = ['1900s']
      @object.save

      expect(DRI.queue).to receive(:push).with(an_instance_of(LinkedDataJob))
      service.call
    end

    it 'does not enqueue a LinkedDataJob when there is no geographic or coverage data' do
      @object.geographical_coverage = []
      @object.coverage = []
      @object.save

      expect(DRI.queue).not_to receive(:push).with(an_instance_of(LinkedDataJob))
      service.call
    end

    it 'does not raise when the linked data job submission fails' do
      @object.geographical_coverage = ['Dublin']
      @object.save

      allow(DRI.queue).to receive(:push).and_raise(StandardError, 'queue unavailable')
      expect { service.call }.not_to raise_error
    end
  end

  # ------------------------------------------------------------- DOI sync

  describe 'DOI sync' do
    before do
      stub_const('DoiConfig', doi_config)
      Settings.doi.enable = true
    end

    after { Settings.doi.enable = false }

    it 'does nothing when no DOI record exists' do
      expect(Resque).not_to receive(:enqueue)
      service.call
    end

    context 'when a DOI record exists' do
      before do
        @doi = DataciteDoi.create(object_id: @object.alternate_id)
        allow(Resque).to receive(:enqueue)
      end
      after  { DataciteDoi.where(object_id: @object.alternate_id).destroy_all }

      it 'enqueues UpdateDoiJob when non-mandatory fields are updated' do
        allow(@doi).to receive(:changed?).and_return(true)
        allow(@doi).to receive(:mandatory_update?).and_return(false)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)

        expect(Resque).to receive(:enqueue).with(UpdateDoiJob, @doi.id)
        service.call
      end

      it 'mints a new DOI when mandatory fields change on a published object' do
        @object.status = 'published'
        @object.save

        allow(@doi).to receive(:changed?).and_return(true)
        allow(@doi).to receive(:mandatory_update?).and_return(true)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)

        expect {
          service.call
        }.to change { DataciteDoi.count }.by(1)
      end

      it 'enqueues MintDoiJob for the new DOI on a mandatory field change' do
        @object.status = 'published'
        @object.save

        allow(@doi).to receive(:changed?).and_return(true)
        allow(@doi).to receive(:mandatory_update?).and_return(true)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)

        expect(Resque).to receive(:enqueue).with(MintDoiJob, anything)
        service.call
      end

      it 'rolls back a new DataciteDoi when the object save fails' do
        @object.status = 'published'
        @object.save

        allow(@doi).to receive(:changed?).and_return(true)
        allow(@doi).to receive(:mandatory_update?).and_return(true)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)
        allow(@object).to receive(:save).and_return(false)

        expect {
          expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
        }.not_to change { DataciteDoi.count }
      end

      it 'does not enqueue any job when the object save fails' do
        allow(@doi).to receive(:changed?).and_return(true)
        allow(DataciteDoi).to receive(:find_by).and_return(@doi)
        allow(@object).to receive(:save).and_return(false)

        expect(Resque).not_to receive(:enqueue)
        expect { service.call }.to raise_error(DRI::Exceptions::InternalError)
      end
    end
  end
end