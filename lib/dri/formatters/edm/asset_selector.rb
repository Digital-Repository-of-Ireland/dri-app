# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Determines the EDM object type for a record and picks the "main"
      # asset (and cleans the asset list) used to represent it.
      class AssetSelector
        def self.edm_type(types)
          types = Array(types).map(&:upcase)

          return "3D" if types.include?(Settings.edm._3d)
          return "VIDEO" if types.to_set.intersect?(Settings.edm.video.to_set)
          return "SOUND" if types.to_set.intersect?(Settings.edm.sound.to_set)
          return "TEXT" if types.include?(Settings.edm.text)
          return "IMAGE" if types.to_set.intersect?(Settings.edm.image.to_set)

          "INVALID"
        end

        # Remove any formats that we don't want to aggregate.
        # Currently just xml files that are pdf surrogates.
        def self.clean(assets)
          assets.select { |obj| obj.key?("file_type_tesim") && !obj["mime_type_tesim"].include?("text/xml") }
        end

        def self.find_by_type(assets, type)
          assets.find { |obj| obj.key?("file_type_tesim") && obj["file_type_tesim"].include?(type) }
        end

        # Picks the file that should be treated as the main asset for a
        # given edm type. When there's more than one candidate file, this
        # decides which one wins.
        def self.mainfile_for_type(edmtype, assets, iiif_main = false)
          case edmtype
          when "VIDEO"
            find_by_type(assets, "video")
          when "SOUND"
            # NOTE: previously written as `include? "audio" || "sound"`, which
            # (due to Ruby operator precedence) always tested for "audio"
            # only. Fixed here to genuinely check both.
            find_by_type(assets, "audio") || find_by_type(assets, "sound")
          when "TEXT"
            if iiif_main
              find_by_type(assets, "image")
            else
              find_by_type(assets, "text") || find_by_type(assets, "image")
            end
          when "IMAGE"
            find_by_type(assets, "image")
          when "3D"
            find_by_type(assets, "3d")
          end
        end
      end
    end
  end
end
