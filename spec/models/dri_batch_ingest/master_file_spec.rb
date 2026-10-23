require 'rails_helper'

describe DRIBatchIngest::MasterFile, type: :model do

  describe "Associations" do
    it { should belong_to(:media_object) }
  end

  it 'should return true if it is metadata' do
    mf = described_class.new
    mf.metadata = true
    expect(mf.metadata?).to be true

    mf.metadata = false
    expect(mf.metadata?).to be false
  end

  it 'should return true if it is preservation asset' do
    mf = described_class.new
    mf.preservation = true
    expect(mf.preservation?).to be true

    mf.preservation = false
    expect(mf.preservation?).to be false
  end

  it 'should be finished processing if in end state' do
    mf = described_class.new
    mf.status_code = 'PENDING'
    expect(mf.finished_processing?).to be false

    DRIBatchIngest::MasterFile::END_STATES.each do |e|
      mf.status_code = e
      expect(mf.finished_processing?).to be true
    end
  end
end
