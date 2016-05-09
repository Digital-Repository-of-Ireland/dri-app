class Licence < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  validates_uniqueness_of :name

  def add_logo(upload, opts = {})
    self.name = opts[:name]
    self.url = opts[:url]

    begin
      save
    rescue ActiveRecord::ActiveRecordError, Exceptions::LicenceError => e
      logger.error "Could not save licence: #{e.message}"
      raise Exceptions::InternalError
    end

    validate_logo(upload)
    store_logo(upload, name)
    save
  end

  def get_logo
    self.logo
  end

  def logo_mime_type(logo)
    mime_object = Validators.file_type?(logo)
    return mime_object.mediatype if mime_object.respond_to?('mediatype')
    return mime_object.media_type if mime_object.respond_to?('media_type')
    return mime_object if mime_object.is_a?(String)
  end

  def store_logo(logo, name)
    type = logo_mime_type(logo)

    if Settings.restrict.mime_types.image.include?(type)
      ext = logo.original_filename.split(".").last

      storage = Storage::S3Interface.new
      storage.store_file(logo.tempfile.path,
                         "#{name}.#{ext}",
                         Settings.data.logos_bucket)
      self.logo = storage.file_url(Settings.data.logos_bucket,
                                            "#{name}.#{ext}")
    end
  end

  def validate_logo(logo)
    raise Exceptions::UnknownMimeType if logo.blank?

    Validators.virus_scan(logo)
  end
end
