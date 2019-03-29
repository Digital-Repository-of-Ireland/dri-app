require "dri/derivatives/extract_metadata"

DRI::Derivatives::ExtractMetadata.module_eval do
  # Quick fixes to get the content from storage and avoid using the REST API

  #def uri_to_id
  #  translate_uri_to_id.call(uri).split('/').first
  #end

  def local_file_info
    @local_file_info ||= LocalFile.where(fedora_id: id, ds_id: "content").order("VERSION DESC").limit(1).take
  end

  def external_body?
    registered_mime_type = MIME::Types[mime_type].first
    registered_mime_type.content_type == "message/external-body"
  end

  def extract_metadata
    unless external_body?
      Hydra::FileCharacterization.characterize(content, filename_for_characterization.join(""), :fits) do |config|
        config[:fits] = Settings.plugins.fits_path
      end
      return
    end

    path = local_file_info.path

    # Bit of a hack here to force mp2 files to be characterized in FITS
    # We have to pretend it's an mp3 by creating a tempfile with an mp3 extension
    if (path.split(".").last == "mp2")
      temp_file = Tempfile.new(filename_for_characterization)
      temp_file.binmode
      open(path) { |data| temp_file.write data.read}
      temp_file.rewind

      Hydra::FileCharacterization.characterize(temp_file, filename_for_characterization.join(""), :fits) do |config|
        config[:fits] = Settings.plugins.fits_path
      end
    else
      Hydra::FileCharacterization.characterize(File.open(path), filename_for_characterization.join(""), :fits) do |config|
        config[:fits] = Settings.plugins.fits_path
      end
    end
  end

  protected

  def filename_for_characterization
    if external_body?
      extension = "."+local_file_info.path.split(".").last
      version_id = local_file_info.version
    else
      registered_mime_type = MIME::Types[mime_type].first
      Logger.warn "Unable to find a registered mime type for #{mime_type.inspect}" unless registered_mime_type
      extension = registered_mime_type ? ".#{registered_mime_type.extensions.first}" : ''
      version_id = 1
    end

    extension = '.mp3' if extension == '.mp2'

    ["#{id}-#{version_id}", "#{extension}"]
  end
end
