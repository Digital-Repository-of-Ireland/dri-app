class Licence < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  attr_accessible :name, :url, :logo, :description

  validates_uniqueness_of :name

  def add_logo(upload,opts={})
    self.name = opts[:name]
    self.url = opts[:url]

    begin
      self.save
    rescue ActiveRecord::ActiveRecordError, Exceptions::LicenceError => e
      logger.error "Could not save licence: #{e.message}"
      raise Exceptions::InternalError
    end

    validate_and_store_logo(upload, self.name)
    self.save
  end


  def get_logo()
    self.logo
  end


  def validate_and_store_logo(logo, name)

    if (logo.nil? || logo.blank?)
      raise Exceptions::UnknownMimeType
    else
      mime_object = Validators.file_type?(logo)
      type = mime_object.mediatype if mime_object.respond_to?('mediatype')
      type = mime_object.media_type if mime_object.respond_to?('media_type')
    end

    if type == "image"
      Validators.virus_scan(logo)

      storage = Storage::S3Interface.new
      storage.store_file(logo.tempfile.path,
                         "#{name}.#{logo.original_filename.split(".").last}",
                         Settings.data.logos_bucket)
      self.logo = storage.get_link_for_file(Settings.data.logos_bucket,
                                            "#{name}.#{logo.original_filename.split(".").last}")

      storage.close
    end
  end
end
