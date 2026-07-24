# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Renders a Context into the array-of-lines linkset format (one
      # "<href> ; rel=... ; type=... ; anchor=..." string per link).
      class LsetRenderer
        def initialize(context)
          @context = context
        end

        def render
          lines = []

          lines << link_line("https://doi.org/#{context.doi}", rel: "cite-as") if context.doi.present?

          lines << link_line(context.schema_link, rel: "type") if context.schema_link.present?
          lines << link_line("https://schema.org/AboutPage", rel: "type")

          Array(context.orcid_links).each do |orcid|
            lines << link_line(orcid, rel: "author")
          end

          Array(context.link_descendants).each do |asset|
            lines << link_line(asset[:href], rel: "item", type: asset[:type])
          end

          lines << link_line(context.describedby[:href], rel: "describedby", type: "application/xml")

          lines << link_line(context.license_link, rel: "license") if context.license_link.present?
          lines << link_line(context.copyright_link, rel: "copyright") if context.copyright_link.present?

          context.reverse_link.each do |item|
            collection = item[:collection].first
            lines << link_line(collection[:href], rel: "collection", type: collection[:type], anchor: item[:anchor])
          end

          lines
        end

        private

        attr_reader :context

        def link_line(href, rel:, type: nil, anchor: context.anchor_url)
          parts = ["<#{href}>", "rel=\"#{rel}\""]
          parts << "type=\"#{type}\"" if type.present?
          parts << "anchor=\"#{anchor}\""
          parts.join(" ; ")
        end
      end
    end
  end
end
