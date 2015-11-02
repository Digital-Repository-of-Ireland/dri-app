class Institute < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  validates_uniqueness_of :name

  def add_logo(upload, opts = {})
    self.name = opts[:name]
    self.url = opts[:url]

    begin
      save
    rescue ActiveRecord::ActiveRecordError, Exceptions::InstituteError => e
      logger.error "Could not save institute: #{e.message}"
      raise Exceptions::InternalError
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
    return false if logo.blank? || Validators.media_type?(logo) != 'image'

    begin
      Validators.virus_scan(logo)

      valid = true
    rescue Exceptions::VirusDetected => e
      logger.error "Virus detected in institute logo: #{e.message}"
      valid = false
    end

    valid
  end

  def store_logo(logo, name)
    storage = Storage::S3Interface.new

    file_ext = logo.original_filename.split('.').last
    storage.store_file(logo.tempfile.path,
                       "#{name}.#{file_ext}",
                       Settings.data.logos_bucket)

    self.logo = storage.get_link_for_file(Settings.data.logos_bucket,
                                          "#{name}.#{file_ext}")
  end
end
