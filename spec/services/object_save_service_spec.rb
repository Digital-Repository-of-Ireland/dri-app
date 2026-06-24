require 'rails_helper'

describe ObjectSaveService do
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

  # --------------------------------------------------------- result interface

  describe 'result' do
    it 'returns a successful result when the object saves and indexes' do
      result = ObjectSaveService.new(@object).call
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.error).to be_nil
    end

    it 'returns a failed result when the object fails to save' do
      allow(@object).to receive(:save).and_return(false)
      result = ObjectSaveService.new(@object).call
      expect(result).to be_failure
      expect(result).not_to be_success
    end

    it 'returns a failed result when indexing fails' do
      allow(@object).to receive(:update_index).and_return(false)
      result = ObjectSaveService.new(@object).call
      expect(result).to be_failure
    end

    it 'returns a failed result on a Solr 400 error' do
      request  = {}
      response = { status: 400, body: '', headers: {} }
      allow(@object).to receive(:update_index).and_raise(RSolr::Error::Http.new(request, response))

      result = ObjectSaveService.new(@object).call
      expect(result).to be_failure
      expect(result.error).to be_a(DRI::SolrBadRequest)
    end
  end

  # ------------------------------------------------------------ save behaviour

  describe 'save behaviour' do
    it 'persists changes to the object' do
      @object.title = ['Updated title']
      ObjectSaveService.new(@object).call
      expect(@object.reload.title).to eq(['Updated title'])
    end

    it 'rolls back the object save when indexing fails' do
      original_title = @object.title.dup
      @object.title  = ['A changed title']

      allow(@object).to receive(:update_index).and_return(false)
      ObjectSaveService.new(@object).call

      expect(@object.reload.title).to eq(original_title)
    end

    it 'sets index_needs_update to false before saving' do
      @object.index_needs_update = true
      ObjectSaveService.new(@object).call
      expect(@object.index_needs_update).to be false
    end
  end

  # --------------------------------------------------------- DOI integration

  describe 'DOI integration' do
    before do
      stub_const('DoiConfig', doi_config)
      Settings.doi.enable = true
      @doi = DataciteDoi.create(object_id: @object.alternate_id)
      allow(Resque).to receive(:enqueue)
    end

    after do
      DataciteDoi.where(object_id: @object.alternate_id).destroy_all
      Settings.doi.enable = false
    end

    it 'updates DOI metadata from doi_params' do
      expect(@doi).to receive(:update_metadata).with(hash_including('title' => anything))
      ObjectSaveService.new(@object, doi: @doi, doi_params: { 'title' => 'New title' }).call
    end

    it 'remaps type to resource_type in doi_params' do
      expect(@doi).to receive(:update_metadata).with(hash_including('resource_type' => 'Sound'))
      expect(@doi).not_to receive(:update_metadata).with(hash_including('type' => anything))
      ObjectSaveService.new(@object, doi: @doi, doi_params: { 'type' => 'Sound' }).call
    end

    it 'returns the DoiSyncService instance on success so the caller can enqueue' do
      result = ObjectSaveService.new(@object, doi: @doi, doi_params: {}).call
      expect(result.doi_sync).to be_a(DoiSyncService)
    end

    it 'returns nil doi_sync on failure' do
      allow(@object).to receive(:save).and_return(false)
      result = ObjectSaveService.new(@object, doi: @doi, doi_params: {}).call
      expect(result.doi_sync).to be_nil
    end

    it 'rolls back a new DataciteDoi record when the object save fails' do
      @object.status = 'published'
      @object.save
      allow(@doi).to receive(:changed?).and_return(true)
      allow(@doi).to receive(:mandatory_update?).and_return(true)
      allow(@object).to receive(:save).and_return(false)

      expect {
        ObjectSaveService.new(@object, doi: @doi, doi_params: { 'title' => 'Changed' }).call
      }.not_to change { DataciteDoi.count }
    end

    it 'does not enqueue any job when the object save fails' do
      allow(@object).to receive(:save).and_return(false)
      expect(Resque).not_to receive(:enqueue)

      result = ObjectSaveService.new(@object, doi: @doi, doi_params: {}).call
      result.doi_sync&.enqueue_job(@doi)
    end

    it 'does not call DOI sync when no doi is passed' do
      expect(DoiSyncService).not_to receive(:new)
      ObjectSaveService.new(@object).call
    end
  end
end