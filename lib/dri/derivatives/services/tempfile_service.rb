module DRI::Derivatives::Services
  class TempfileService < Hydra::Derivatives::TempfileService
    def tempfile(&block)
      Tempfile.open(temp_filename) do |f|
        f.binmode
        if source_file.respond_to? :read
          f.write(source_file.read)
        else
          f.write(source_file)
        end
        source_file.rewind if source_file.respond_to? :rewind
        f.rewind
        yield(f)
      end
    end

    def temp_filename
      registered_mime_type = MIME::Types[source_file.mime_type].first
      Logger.warn "Unable to find a registered mime type for #{source_file.mime_type.inspect} on #{source_file.original_filename}" unless registered_mime_type
      extension = registered_mime_type ? ".#{registered_mime_type.extensions.first}" : ''

      extension = '.mp3' if extension == '.mp2'
      version_id = 1 # TODO fixme

      ["#{source_file.original_filename}-#{version_id}", "#{extension}"]
    end
  end
end
