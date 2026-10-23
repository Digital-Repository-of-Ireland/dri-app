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
        path = Pathname.new(file_path)
        (url, extra) = provider_file_info(user, path, opts)

        result = { 'url' => url }
        result.merge!(extra.stringify_keys) unless extra.nil?
        result['expires'] = result['expires'].iso8601 if result.key?('expires')

        result
      end

      def provider_file_info(user, file_path, opts)
        url_options = BrowseEverything.config
        url_options['sandbox_file_system'][:current_user] = user.email if url_options['sandbox_file_system'].present?

        browser = BrowseEverything::Browser.new(url_options)
        browser.providers.values.each do |p|
          p.token = opts["#{p.key}_token"]
        end
        if opts['provider'] == 'sandbox_file_system' && browser.providers['sandbox_file_system']&.home
          file_path = File.join(browser.providers['sandbox_file_system'].home, file_path)
          browser.providers[opts['provider']].link_for(file_path.to_s)
        else
          browser.providers['file_system'].link_for(file_path.to_s)
        end
      end
    end
  end
end
