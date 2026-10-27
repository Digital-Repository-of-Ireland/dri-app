# frozen_string_literal: true
require 'avalon/batch'

module DRIBatchIngest
  module Processors
    class EntryProcessor < Avalon::Batch::Entry
      def media_object
        @media_object ||= DRIBatchIngest::MediaObject.new(collection: @manifest.package.collection)
      end

      def process!(opts = {})
        batch = DRIBatchIngest::IngestBatch.find(opts['batch'])
        user = UserGroup::User.find(batch.user_ingest.user_id)

        media_object.ingest_batch = batch
        media_object.save

        @files.each do |file_spec|
          master_file = create_master_file(file_spec)
          spec = download_spec(user, file_spec[:file], opts)
          master_file.download_spec = spec.to_json
          master_file.file_size = spec['file_size'] if spec.key?('file_size')
          master_file.file_location = file_spec['file']
          media_object.save if master_file.save
        end

        media_object
      end

      private

      def create_master_file(file_spec)
        master_file = DRIBatchIngest::MasterFile.new
        master_file.media_object = media_object
        master_file.metadata = true if file_spec.key?(:label) && file_spec[:label] == 'metadata'
        master_file.preservation = true if file_spec.key?(:label) && file_spec[:label] == 'preservation'
        master_file.status_code = 'PENDING'

        master_file
      end

      def download_spec(user, file_path, opts)
        raise ArgumentError, "unsupported provider: #{opts['provider']}" unless opts['provider'] == 'sandbox_file_system'

        full_path = DRIBatchIngest::UserStorage.resolve(user.email, file_path.to_s)
        spec = { 'url' => "file://#{full_path}", 'file_name' => File.basename(full_path) }
        spec['file_size'] = File.size(full_path) if File.file?(full_path)
        spec
      end
    end
  end
end
