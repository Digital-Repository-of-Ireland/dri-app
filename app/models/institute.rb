class Institute < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  has_one :brand

  validates_uniqueness_of :name

  def add_logo(upload, opts = {})
    self.name = opts[:name]
    self.url = opts[:url]

    begin
      save
    rescue ActiveRecord::ActiveRecordError, DRI::Exceptions::InstituteError => e
      logger.error "Could not save institute: #{e.message}"
      raise DRI::Exceptions::InternalError
    end

    valid = validate_logo upload
    store_logo(upload, name) if valid

    save
  end

  def self.find_collection_institutes(institute_list)
    return nil if institute_list.blank?

    institutes = where(name: institute_list)
    institutes.blank? ? nil : institutes.to_a
  end

  def local_storage_dir
    Rails.root.join(Settings.dri.logos)
  end

  def validate_logo(logo)
    return false if logo.blank? || Validators.media_type(logo) != 'image'

    begin
      Validators.virus_scan(logo)

      valid = true
    rescue DRI::Exceptions::VirusDetected => e
      logger.error "Virus detected in institute logo: #{e.message}"
      valid = false
    end

    valid
  end

  def store_logo(upload, name)
    b = self.brand || Brand.new
    b.filename = upload.original_filename
    b.content_type = upload.content_type
    b.file_contents = upload.read
    b.save

    self.brand = b
  end
end
