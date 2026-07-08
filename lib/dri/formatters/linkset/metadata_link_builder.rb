# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Builds the "describedby" link pointing at a document's own XML
      # metadata, including an optional XML schema profile when we
      # recognise the underlying metadata class.
      class MetadataLinkBuilder
        def initialize(controller)
          @controller = controller
        end

        def build(document)
          link = {
            href: @controller.object_metadata_url(document.id),
            type: "application/xml"
          }

          profile = SchemaTypeMapper.lookup(document["has_model_ssim"], SchemaTypeMapper::XML_PROFILE)
          link[:profile] = profile if profile.present?

          link
        end
      end
    end
  end
end
