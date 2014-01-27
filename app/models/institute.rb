class Institute < ActiveRecord::Base
  require 'storage/s3_interface'
  require 'validators'

  attr_accessible :name, :url, :logo

  validates_uniqueness_of :name

  def add_logo(upload,opts={})
    self.name = opts[:name]
    self.url = opts[:url]

    begin
      self.save
    rescue ActiveRecord::ActiveRecordError, Exceptions::InstituteError => e
      logger.error "Could not save institute: #{e.message}"
      raise Exceptions::InternalError
    end

    validate_and_store_logo(upload, self.name)
    self.save
  end


  def get_logo()


  end


  def local_storage_dir
    Rails.root.join(Settings.dri.logos)
  end


  def validate_and_store_logo(logo, name)
    if !logo.blank? && Validators.file_type?(logo).mediatype == "image"
      begin
        Validators.virus_scan(logo)
      rescue Exceptions::VirusDetected => e
        virus = true
        flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
      end

      unless virus
        AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                           :access_key_id => Settings.S3.access_key_id,
                                           :secret_access_key => Settings.S3.secret_access_key)
        AWS::S3::Service.buckets

        Storage::S3Interface.store_file(logo.tempfile.path,
                                        "#{name}.#{logo.original_filename.split(".").last}",
                                        Settings.data.logos_bucket)
        self.logo = Storage::S3Interface.get_link_for_file(Settings.data.logos_bucket,
                                                          "#{name}.#{logo.original_filename.split(".").last}")

        AWS::S3::Base.disconnect!()
      end
    end
  end
end
