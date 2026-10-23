require 'rails_helper'

describe DRIBatchIngest::Processors::EntryProcessor do

  describe 'process' do

    let(:dummy_manifest) { Class.new {
      def package
        Class.new {
          def collection
            'test-1'
          end
        }.new
      end
      }
    }

    let(:user) { FactoryBot.build(:collection_manager) }
    let(:user_ingest) { DRIBatchIngest::UserIngest.new }
    let(:ingest_batch) { DRIBatchIngest::IngestBatch.new }

    it 'should process an entry' do
      user_ingest.user = user
      user_ingest.save

      ingest_batch.user_ingest = user_ingest
      ingest_batch.save

      files = []
      files << { label: 'metadata', file: 'metadata/object_1.xml' }
      files << { label: 'asset', file: 'assets/object_1.png' }

      processor = described_class.new({}, files, {}, 1, dummy_manifest.new)
      allow(processor).to receive(:provider_file_info) do |_user, path, _opts|
        ["file:///tmp/#{path}", { file_name: File.basename(path.to_s), file_size: 1234 }]
      end

      expect {
        processor.process!('batch' => ingest_batch.id, 'provider' => 'sandbox_file_system')
      }.to change { DRIBatchIngest::MediaObject.count }.by(1)

      expect(ingest_batch.media_objects.count).to eq 1
      expect(ingest_batch.media_objects.first.parts.count).to eq 2

      user_ingest.destroy
    end

  end
end
