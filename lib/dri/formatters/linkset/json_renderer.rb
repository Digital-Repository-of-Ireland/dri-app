# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Renders a Context into the pretty-printed JSON linkset structure.
      class JsonRenderer
        def initialize(context)
          @context = context
        end

        def render
          linkset = { anchor: context.anchor_url }

          linkset[:"cite-as"] = [{ href: "https://doi.org/#{context.doi}" }] if context.doi.present?

          linkset[:type] = if context.schema_link.present?
                             [{ href: context.schema_link }, { href: "https://schema.org/AboutPage" }]
                           else
                             [{ href: "https://schema.org/AboutPage" }]
                           end

          if context.orcid_links.present?
            linkset[:author] = context.orcid_links.map { |orcid| { href: orcid } }
          end

          linkset[:item] = context.link_descendants if context.link_descendants.present?
          linkset[:describedby] = [context.describedby]
          linkset[:license] = [{ href: context.license_link }] if context.license_link.present?
          linkset[:copyright] = [{ href: context.copyright_link }] if context.copyright_link.present?

          JSON.pretty_generate("linkset" => [linkset, context.reverse_link])
        end

        private

        attr_reader :context
      end
    end
  end
end
