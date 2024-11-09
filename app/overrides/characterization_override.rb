require "dri/derivatives/extract_metadata"

DRI::Derivatives::ExtractMetadata.module_eval do
  # Quick fixes to get the content from storage and avoid using the REST API
  def extract_metadata
    # Bit of a hack here to force mp2 files to be characterized in FITS
    # We have to pretend it's an mp3 by creating a tempfile with an mp3 extension
    if (File.extname(path) == ".mp2")
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
      extension = File.extname(path)

      if (extension == '.mp2')
        extension = '.mp3'
      end
      version_id = 1 # TODO fixme

      ["#{alternate_id}-#{version_id}", "#{extension}"]
    end
end
