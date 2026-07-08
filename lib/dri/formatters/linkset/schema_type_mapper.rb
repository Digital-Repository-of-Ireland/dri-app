# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Maps DRI/Fedora-ish type strings (asset types, has_model_ssim
      # class names) onto external vocabulary URLs. Used both for the
      # schema.org "rel=type" link and the XML profile on "describedby".
      class SchemaTypeMapper
        SCHEMA_TYPES = {
          "text" => "https://schema.org/DigitalDocument",
          "image" => "https://schema.org/ImageObject",
          "movingimage" => "https://schema.org/VideoObject",
          "interactiveresource" => "https://schema.org/WebApplication",
          "sound" => "https://schema.org/AudioObject",
          "software" => "https://schema.org/SoftwareApplication",
          "dataset" => "https://schema.org/Dataset",
          "article" => "https://schema.org/ScholarlyArticle",
          "collection" => "https://schema.org/Collection",
          "object" => "https://schema.org/object",
          "3d" => "https://schema.org/3DModel"
        }.freeze

        XML_PROFILE = {
          "dri::qualifieddublincore" => "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd",
          "dri::mods" => "http://www.loc.gov/standards/mods/v3/mods-3-7.xsd",
          "dri::eadcomponent" => "http://www.loc.gov/ead/ead.xsd",
          "dri::eadcollection" => "http://www.loc.gov/ead/ead.xsd",
          "dri:marc" => "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
        }.freeze

        # Returns the first mapped link for any of the given types, or nil
        # if none of them are present in the map. `target_types` may be a
        # single value or an array.
        #
        def self.lookup(target_types, map = SCHEMA_TYPES)
          Array(target_types).each do |type|
            link = map[type.to_s.downcase]
            return link if link.present?
          end

          nil
        end
      end
    end
  end
end
