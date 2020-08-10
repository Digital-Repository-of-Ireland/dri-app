require "image_processing/vips"

module Storage
  module CoverImages

    def self.validate_and_store(cover_image, collection)
      return unless cover_image.present?

      return false unless %w(image/jpeg image/png image/gif).include?(Validators.file_type(cover_image))
      return false if self.virus?(cover_image)

      processed = ImageProcessing::Vips.source(cover_image.path).resize_to_limit!(228, 128)
      url = self.store_cover(processed, cover_image.original_filename, collection)
      unless url
        Rails.logger.error "Unable to save cover image."
        return false
      end
      collection.properties.cover_image = url
      collection.save

      true
    end

    private

    def self.virus?(cover_image)
      Validators.virus_scan(cover_image)
      false
    rescue DRI::Exceptions::VirusDetected => e
      Rails.logger.error("Virus detected in cover image: #{e.message}")
      true
    end

    def self.store_cover(cover_image, filename, collection)
      url = nil
      storage = StorageService.new
      storage.create_bucket(collection.id)

      cover_filename = "#{collection.id}.#{filename.split(".").last}"
      if (
        storage.store_file(
          collection.id,
          cover_image.path,
          cover_filename)
        )
        url = storage.file_url(collection.id, cover_filename)
      end

      url
    end
  end
end
