require 'rails_helper'

describe DRIBatchIngest::MediaObject, type: :model do

  let(:user) { FactoryBot.build(:collection_manager) }
  let(:user_ingest) { DRIBatchIngest::UserIngest.new }
  let(:ingest_batch) { DRIBatchIngest::IngestBatch.new }

  describe "Associations" do
    it { should belong_to(:ingest_batch) }
    it { should have_many(:parts) }
  end

  describe "Parts" do
    it 'should have succeeded if all parts completed' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf.status_code = 'COMPLETED'
      mf2.status_code = 'COMPLETED'

      mo = DRIBatchIngest::MediaObject.new
      mo.parts << mf
      mo.parts << mf2

      expect(mo.succeeded?).to be true
    end

    it 'should have failed if any part fails' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf.status_code = 'FAILED'
      mf2.status_code = 'COMPLETED'

      mo = DRIBatchIngest::MediaObject.new
      mo.parts << mf
      mo.parts << mf2

      expect(mo.succeeded?).to be false
      expect(mo.failed?).to be true
    end

    it 'should return the metadata part' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf.status_code = 'COMPLETED'
      mf.metadata = true
      mf.save
      mf2.status_code = 'COMPLETED'
      mf2.save

      mo = DRIBatchIngest::MediaObject.create
      mo.parts << mf
      mo.parts << mf2

      expect(mo.metadata.id).to eq mf.id
    end

    it 'should be finished processing if all parts are finished' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf.status_code = 'COMPLETED'
      mf2.status_code = 'COMPLETED'

      mo = DRIBatchIngest::MediaObject.new
      mo.parts << mf
      mo.parts << mf2

      expect(mo.finished_processing?).to be true
    end

    it 'should return finished_at' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf2.status_code = 'PENDING'
      mf2.save

      mf.status_code = 'COMPLETED'
      mf.save

      mo = DRIBatchIngest::MediaObject.create
      mo.parts << mf2
      mo.parts << mf

      mf2.status_code = 'COMPLETED'
      mf2.save
      mf2.reload

      expect(mo.finished_at).to eq mf2.updated_at
    end
  end

  describe "destroy" do
    it 'should destroy parts' do
      mf = DRIBatchIngest::MasterFile.new
      mf2 = DRIBatchIngest::MasterFile.new
      mf2.status_code = 'PENDING'
      mf2.save

      mf.status_code = 'COMPLETED'
      mf.save

      mo = DRIBatchIngest::MediaObject.create
      mo.parts << mf2
      mo.parts << mf

      expect { mo.destroy }.to change{ DRIBatchIngest::MasterFile.all.count }.by(-2)
    end
  end
end
