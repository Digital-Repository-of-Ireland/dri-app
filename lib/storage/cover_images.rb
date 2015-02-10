module Storage
  module CoverImages

    require 'utils'

    def self.validate(cover_image, collection)
      if !cover_image.blank? && Validators.file_type?(cover_image).mediatype == "image"
        begin
          Validators.virus_scan(cover_image)
        rescue Exceptions::VirusDetected => e
          Rails.logger.error("Virus detected in cover image: #{e.message}")

          return false
        end

        storage = Storage::S3Interface.new
        if (storage.store_file(cover_image.tempfile.path,
                                   "#{Utils.split_id(collection.pid)}.#{cover_image.original_filename.split(".").last}",
                                   Settings.data.cover_image_bucket))
          url = storage.get_link_for_file(Settings.data.cover_image_bucket,
                          "#{Utils.split_id(collection.pid)}.#{cover_image.original_filename.split(".").last}")

          collection.properties.cover_image = url
          collection.save
 
          return true
        else
          Rails.logger.error "Unable to save cover image."
          return false
        end
      end
    end
    
    # FIXME - Initial impl of creation of EAD cover images from the data models...
    def self.validate_from_tempfile(cover_image, collection)
      if !cover_image.blank? && Validators.file_type?(cover_image).mediatype == "image"
        begin
          Validators.virus_scan(cover_image)
        rescue Exceptions::VirusDetected => e
          Rails.logger.error("Virus detected in cover image: #{e.message}")

          return false
        end

        storage = Storage::S3Interface.new
        if (storage.store_file(cover_image.path,
                                   "#{Utils.split_id(collection.pid)}.#{cover_image.path.split(".").last}",
                                   Settings.data.cover_image_bucket))
          url = storage.get_link_for_file(Settings.data.cover_image_bucket,
                          "#{Utils.split_id(collection.pid)}.#{cover_image.path.split(".").last}")

          collection.properties.cover_image = url

          # From data models, when creating cover image, no need to save the object here!!
          #collection.save
 
          return true
        else
          Rails.logger.error "Unable to save cover image."
          return false
        end
      end
    end

  end
end
