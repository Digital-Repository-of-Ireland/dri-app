# frozen_string_literal: true
require "image_processing/mini_magick"

module Storage
  module CoverImages
    def self.validate_and_store(cover_image, collection)
      return if cover_image.blank?
      return false unless %w[image/jpeg image/png image/gif].include?(Validators.file_type(cover_image))
      return false if virus?(cover_image)

      processed = ImageProcessing::MiniMagick.source(cover_image.path)
                                             .resize_and_pad!(228, 128)      
      url = store_cover(processed, cover_image.original_filename, collection)
      unless url_valid?(url)
        Rails.logger.error "Unable to save cover image."
        return false
      end
      
      collection.cover_image = url
      collection.save

      true
    end

    def self.virus?(cover_image)
      Validators.virus_scan(cover_image)
      false
    rescue DRI::Exceptions::VirusDetected => e
      Rails.logger.error("Virus detected in cover image: #{e.message}")
      true
    end

    def self.store_cover(cover_image, filename, collection)
      storage = StorageService.new
      storage.create_bucket(collection.alternate_id)

      cover_filename = "#{collection.id}.#{filename.split('.').last}"
      return unless storage.store_file(collection.alternate_id, cover_image.path, cover_filename)
      storage.file_url(collection.alternate_id, cover_filename)
    end

    def self.url_valid?(url)
      return false unless url
      URI.parse(url)

      true
    rescue URI::InvalidURIError
      false
    end
  end
end
