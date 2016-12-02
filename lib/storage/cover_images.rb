module Storage
  module CoverImages

    def self.validate_and_store(cover_image, collection)
      if cover_image.present?
        return false unless %w(image/jpeg image/png image/gif).include?(Validators.file_type(cover_image))

        return false if self.virus?(cover_image)

        url = self.store_cover(cover_image, collection)
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
    rescue DRI::Exceptions::VirusDetected => e
      Rails.logger.error("Virus detected in cover image: #{e.message}")
      true
    end

    def self.store_cover(cover_image, collection)
      url = nil
      storage = StorageService.new
      storage.create_bucket(collection.pid)

      if (storage.store_file(collection.pid, cover_image.tempfile.path,
            "#{collection.pid}.#{cover_image.original_filename.split(".").last}"))
        url = storage.file_url(collection.pid,
            "#{collection.pid}.#{cover_image.original_filename.split(".").last}")
      end
      
      url
    end
  end
end
