# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Builds the various asset/thumbnail/DOI URLs used in the EDM output.
      # Needs a controller (for url_helpers + riiif) because that's how the
      # original formatter accessed routing/image-server helpers.
      class UrlBuilder
        attr_reader :controller

        def initialize(controller)
          @controller = controller
        end

        def riiif
          controller.riiif
        end

        def valid_url?(url)
          uri = URI.parse(url)
          (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && !uri.host.nil?
        rescue URI::InvalidURIError
          false
        end

        def doi_url(record, doi_from_metadata = false)
          if doi_from_metadata
            found = find_doi_in_metadata(record)
            return found if found.present?
          end

          return nil if record.doi.blank?

          doi = record.doi.is_a?(Array) ? record.doi.first : record.doi
          "https://doi.org/#{doi}"
        end

        def object_3d_url(record)
          "#{controller.api_oembed_url}?url=#{controller.catalog_url(record.id)}"
        end

        # The URL used for edm:isShownBy / edm:hasView / plain asset
        # edm:WebResource entries, based on file type.
        def file_url_for(record, file)
          return nil unless file&.key?("file_type_tesim")

          types = file["file_type_tesim"]

          if types.include?("video")
            controller.object_file_url(record.id, file.id, surrogate: "mp4")
          elsif types.include?("audio") || types.include?("sound")
            controller.object_file_url(record.id, file.id, surrogate: "mp3")
          elsif types.include?("text")
            controller.object_file_url(record.id, file.id, surrogate: "pdf")
          elsif types.include?("image")
            riiif.image_url("#{record.id}:#{file.id}", size: "full")
          elsif types.include?("3d")
            object_3d_url(record)
          end
        end

        def thumbnail_url(record, file, image = nil)
          return nil if file.blank?

          types = file["file_type_tesim"]

          if types.include?("video")
            controller.object_file_url(record.id, file.id, surrogate: "thumbnail")
          elsif types.include?("audio") || types.include?("sound")
            fallback_or_cover(record, image)
          elsif types.include?("text")
            image.present? ? riiif.image_url("#{record.id}:#{image.id}", size: "500,") : controller.object_file_url(record.id, file.id, surrogate: "lightbox_format")
          elsif types.include?("image")
            riiif.image_url("#{record.id}:#{file.id}", size: "500,")
          elsif types.include?("3d")
            fallback_or_cover(record, image)
          end
        end

        private

        def fallback_or_cover(record, image)
          if image.present?
            controller.object_file_url(record.id, image.id, surrogate: "lightbox_format")
          else
            controller.cover_image_url(record.collection_id)
          end
        end

        # Previously implemented with a bare `find { ... }; return $1 unless
        # $1.blank?` - the find's return value was discarded and $1 was
        # relied on as a side effect of the last regex match evaluated
        # inside the block, which only works when the *last* item checked
        # happens to be the match. Rewritten to capture the match directly.
        def find_doi_in_metadata(record)
          %w[source_tesim qdc_id_tesim].each do |field|
            next unless record[field]

            # NOTE: previously `/(https:\/\/doi\.org.*\/.*)/`, a greedy match
            # that swallowed any trailing text on the same line (e.g. "...
            # https://doi.org/10.5555/xyz for details" would incorrectly
            # capture " for details" too). DOI URLs don't contain whitespace,
            # so we stop at the first whitespace instead.
            match = record[field].map { |e| e[%r{(https://doi\.org\S+)}, 1] }.compact.first
            return match if match.present?
          end

          nil
        end
      end
    end
  end
end