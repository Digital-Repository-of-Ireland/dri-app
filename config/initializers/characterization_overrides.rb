require "hydra/derivatives/extract_metadata"
# require "sufia/models/file_content"

Hydra::Derivatives::ExtractMetadata.module_eval do
  # Quick fixes to get the content from storage and avoid using the REST API

  def id
    /\/([^\/]*)$/.match(uri.value.rpartition('/')[0])[1]
  end

  def external_body?
    registered_mime_type = MIME::Types[mime_type].first
    registered_mime_type.content_type == "message/external-body"
  end

  def extract_metadata
    
    if external_body?
      @local_file_info = LocalFile.where(fedora_id: id, ds_id: "content").order("VERSION DESC").limit(1).to_a
      path = @local_file_info[0].path

      # Bit of a hack here to force mp2 files to be characterized in FITS
      # We have to pretend it's an mp3 by creating a tempfile with an mp3 extension
      if (path.split(".").last == "mp2")
        temp_file = Tempfile.new(filename_for_characterization)
        temp_file.binmode
        open(path) { |data| temp_file.write data.read}
        temp_file.rewind

        Hydra::FileCharacterization.characterize(temp_file, filename_for_characterization.join(""), :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      else
        Hydra::FileCharacterization.characterize(File.open(path), filename_for_characterization.join(""), :fits) do |config|
          config[:fits] = Hydra::Derivatives.fits_path
        end
      end
    else
      Hydra::FileCharacterization.characterize(content, filename_for_characterization.join(""), :fits) do |config|
        config[:fits] = Hydra::Derivatives.fits_path
      end
    end

  end

  def to_tempfile(&block)
    source = nil

    if external_body?
      @local_file_info = LocalFile.where(fedora_id: id, ds_id: "content").order("VERSION DESC").limit(1).to_a
      source = File.open(@local_file_info[0].path, 'r')
    else
      source = content
    end

    Tempfile.open(filename_for_characterization) do |f|
        f.binmode
        if source.respond_to? :read
          f.write(source.read)
        else
          f.write(source)
        end
        source.rewind if source.respond_to? :rewind
        f.rewind
        yield(f)
    end
  end

  protected

    def filename_for_characterization
      extension = ""
      if external_body?
        local_file_info = LocalFile.where(fedora_id: id, ds_id: "content").order("VERSION DESC").limit(1).to_a
        extension = "."+local_file_info[0].path.split(".").last
      else
        registered_mime_type = MIME::Types[mime_type].first
        Logger.warn "Unable to find a registered mime type for #{mime_type.inspect} on #{uri}" unless registered_mime_type
        extension = registered_mime_type ? ".#{registered_mime_type.extensions.first}" : ''
      end

      if (extension == '.mp2')
        extension = '.mp3'
      end
      version_id = 1 # TODO fixme

      ["#{id}-#{version_id}", "#{extension}"]
    end

end
