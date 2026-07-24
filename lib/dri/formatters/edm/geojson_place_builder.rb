# frozen_string_literal: true

module DRI
  module Formatters
    class Edm
      # Turns a record's `geojson_ssim` field (an array of GeoJSON strings)
      # into edm:Place contextual class elements.
      class GeojsonPlaceBuilder
        def initialize(record)
          @record = record
        end

        def write(xml)
          return if @record["geojson_ssim"].blank?

          @record["geojson_ssim"].each do |geojson|
            write_place(xml, JSON.parse(geojson))
          end
        end

        private

        def write_place(xml, place)
          return unless place["geometry"]["type"] == "Point"

          east, north = place["geometry"]["coordinates"]
          return unless north.present? && east.present?

          ga = place["properties"]["nameGA"]
          en = place["properties"]["nameEN"] || place["properties"]["placename"]
          identifier = place["properties"]["uri"] || place["properties"]["placename"] || place["geometry"]["coordinates"].to_s
          about = "##{identifier.tr(' ', '')}"

          xml.tag! "edm:Place", { "rdf:about" => about } do
            xml.tag! "skos:prefLabel", { "xml:lang" => "ga" }, ga unless ga.blank?
            xml.tag! "skos:prefLabel", { "xml:lang" => "en" }, en unless en.blank?
            xml.tag! "wgs84_pos:lat", north
            xml.tag! "wgs84_pos:long", east
          end
        end
      end
    end
  end
end
