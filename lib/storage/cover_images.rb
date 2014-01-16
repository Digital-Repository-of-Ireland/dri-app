module Storage
  module CoverImages

    def self.validate(cover_image, collection)
      if !cover_image.blank? && Validators.file_type?(cover_image).mediatype == "image"
        begin
          Validators.virus_scan(cover_image)
        rescue Exceptions::VirusDetected => e
          virus = true
          flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
        end

        unless virus
          Storage::S3Interface.store_file(cover_image.tempfile.path,
                                          "#{collection.pid.sub('dri:', '')}.#{cover_image.original_filename.split(".").last}",
                                          Settings.data.cover_image_bucket)
          url = Storage::S3Interface.get_link_for_file(Settings.data.cover_image_bucket,
                                                       "#{collection.pid.sub('dri:', '')}.#{cover_image.original_filename.split(".").last}")
          collection.properties.cover_image = url
          collection.save
        end
      end
    end
  end
end
