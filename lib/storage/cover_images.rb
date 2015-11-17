module Storage
  module CoverImages

    def self.validate(cover_image, collection)
      if cover_image.present? && Validators.media_type?(cover_image) == 'image'
        return false if self.virus?(cover_image)

        url = self.store_cover(cover_image.tempfile.path, collection, cover_image.original_filename)
        if url
          collection.properties.cover_image = url
          collection.save
 
          return true
        else
          Rails.logger.error "Unable to save cover image."
          return false
        end
      end
    end

    private

    def self.virus?(cover_image)
      Validators.virus_scan(cover_image)
      false
    rescue Exceptions::VirusDetected => e
      Rails.logger.error("Virus detected in cover image: #{e.message}")
      true
    end

    def self.store_cover(cover_image, collection, filename)
      if !Settings.data || Settings.data.cover_image_bucket.nil?
        Rails.logger.error "Storage bucket for cover images not configured"        
        return nil
      end
      
      url = nil
      storage = Storage::S3Interface.new
      if (storage.store_file(cover_image,
                            "#{collection.pid}.#{filename.split(".").last}",
                             Settings.data.cover_image_bucket))
        url = storage.get_link_for_file(Settings.data.cover_image_bucket,
                         "#{collection.pid}.#{filename.split(".").last}")
      end
      
      url
    end
  end
end
