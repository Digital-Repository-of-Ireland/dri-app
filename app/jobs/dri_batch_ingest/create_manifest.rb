# frozen_string_literal: true
class DRIBatchIngest::CreateManifest
  @queue = :create_manifest

  def self.perform(ingest_id, base_dir, email, collection, metadata_path, asset_path, preservation_path)
    creator = DRIBatchIngest::CsvCreator.new(
      base_dir,
      email,
      collection
    )
    creator.create(metadata_path, asset_path, preservation_path)

    package = Avalon::Batch::Package.new(
      creator.csv_file,
      collection,
      DRIBatchIngest::Processors::EntryProcessor
    )

    ingest = DRIBatchIngest::UserIngest.find(ingest_id)
    batch = DRIBatchIngest::IngestBatch.create(
      collection_id: collection,
      email: package.manifest.email,
      user_ingest_id: ingest.id
    )

    package.process!(
      'batch' => batch.id,
      'provider' => 'sandbox_file_system',
      'file_system_token' => nil
    )

    batch.update!(report: {
      'unmatched_assets' => creator.unmatched_assets,
      'unmatched_preservation' => creator.unmatched_preservation
    })
    ingest.batches << batch
    ingest.save
  rescue StandardError => e
    message = case e
            when Errno::ENOENT then 'The selected directory could not be found.'
            else 'Something went wrong while reading the files. Please try again or contact support.'
            end
    DRIBatchIngest::UserIngest.where(id: ingest_id).update_all(error: message)
    raise
  end
end
