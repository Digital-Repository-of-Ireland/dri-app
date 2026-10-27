require 'rails_helper'
require 'resque'

describe DRIBatchIngest::CreateManifest do

  let(:user) { FactoryBot.create(:collection_manager) }
  let(:user_ingest) { DRIBatchIngest::UserIngest.new }

  it 'should create manifest and start process batch' do
    user_ingest.user_id = user.id
    user_ingest.save

    base_dir = File.join(file_fixture_path, 'ingest')

    expect(Resque).to receive(:enqueue).once

    described_class.perform(
      user_ingest.id,
      base_dir,
      user.email,
      'test1',
      'metadata',
      'data',
      'preservation'
    )

    expect(user_ingest.batches.count).to be 1
    expect(user_ingest.batches.first.media_objects.count).to be 3
    expect(user_ingest.batches.first.media_objects.first.parts.count).to eq 3
    expect(user_ingest.batches.first.media_objects[1].parts.count).to eq 3
    expect(user_ingest.batches.first.media_objects[2].parts.count).to eq 3

    user_ingest.destroy
  end

end
