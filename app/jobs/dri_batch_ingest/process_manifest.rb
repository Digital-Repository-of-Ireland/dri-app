# frozen_string_literal: true
require 'avalon/batch'

class DRIBatchIngest::ProcessManifest
  @queue = :process_manifest

  def self.perform(ingest_id, collection, selected_files, provider_tokens)
    retriever = BrowseEverything::Retriever.new
    ingest = DRIBatchIngest::UserIngest.find(ingest_id)

    FileUtils.mkdir_p(File.join(Settings.downloads.directory, collection))

    selected_files.each do |_key, download_spec|
      provider = download_spec['provider']

      manifest = retrieve_manifest(retriever, collection, download_spec)
      package = Avalon::Batch::Package.new(
        manifest,
        collection,
        DRIBatchIngest::Processors::EntryProcessor
      )

      batch = DRIBatchIngest::IngestBatch.create(collection_id: collection, email: package.manifest.email, user_ingest_id: ingest.id)

      package.process!(
        'batch' => batch.id,
        'provider' => provider,
        "#{provider}_token" => provider_tokens["#{provider}_token"]
      )

      ingest.batches << batch

      Resque.enqueue(DRIBatchIngest::ProcessBatch, batch.id)
    end

    ingest.save
  end

  def self.retrieve_manifest(retriever, collection, download_spec)
    target_file = File.join(Settings.downloads.directory, collection, download_spec['file_name'])
    retriever.download(download_spec, target_file) do |filename, retrieved, total|
    end

    target_file
  end
end
