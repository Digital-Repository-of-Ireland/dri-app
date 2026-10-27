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

    let(:storage_root) { Dir.mktmpdir }
    before do
      allow(Settings.ingest).to receive(:storage_root).and_return(storage_root)
      dir = File.join(storage_root, user.email, 'files')
      FileUtils.mkdir_p(File.join(dir, 'metadata')); FileUtils.mkdir_p(File.join(dir, 'assets'))
      FileUtils.touch(File.join(dir, 'metadata/object_1.xml')); FileUtils.touch(File.join(dir, 'assets/object_1.png'))
    end
    after { FileUtils.remove_entry(storage_root) }

    it 'should process an entry' do
      user_ingest.user = user
      user_ingest.save

      ingest_batch.user_ingest = user_ingest
      ingest_batch.save

      files = []
      files << { label: 'metadata', file: 'metadata/object_1.xml' }
      files << { label: 'asset', file: 'assets/object_1.png' }

      processor = described_class.new({}, files, {}, 1, dummy_manifest.new)

      expect {
        processor.process!('batch' => ingest_batch.id, 'provider' => 'sandbox_file_system')
      }.to change { DRIBatchIngest::MediaObject.count }.by(1)

      spec = JSON.parse(ingest_batch.media_objects.first.parts.first.download_spec)
      expect(spec.keys).to match_array(%w[url file_name file_size])
      expect(spec['url']).to start_with('file://')
      
      expect(ingest_batch.media_objects.count).to eq 1
      expect(ingest_batch.media_objects.first.parts.count).to eq 2

      user_ingest.destroy
    end

  end
end
