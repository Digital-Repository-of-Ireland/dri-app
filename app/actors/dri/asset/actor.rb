module DRI::Asset

  class Actor < Sufia::GenericFile::Actor

    def create_external_content(url, path, file_name)
      IngestStatus.create(object_id: generic_file.batch.id, asset_id: generic_file.id, status: 'processing')
      
      self.create_content('', file_name, path, external_mime_type(url))
    end

    def update_external_content(url, file, path)
      generic_file.add_file('', path: path, original_name: file.original_filename, mime_type: external_mime_type(url))
      
      IngestStatus.create(object_id: generic_file.batch.id, asset_id: generic_file.id, status: 'processing')

      save_characterize_and_record_committer do
        if Sufia.config.respond_to?(:after_update_content)
          Sufia.config.after_update_content.call(generic_file, user)
        end
      end
    end

    private

      def external_mime_type url
        "message/external-body; access-type=URL; URL=\"#{url}\""
      end

  end
end
