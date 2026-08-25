# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Builds the reverse "collection" links: for each descendant link
      # (item), a small structure pointing back at the ancestor
      # collection, anchored on that descendant's own href.
      class ReverseLinkBuilder
        def initialize(controller)
          @controller = controller
        end

        # NOTE: the original also computed an unused `object_link =
        # @controller.catalog_url(object_id)` here (its value was never
        # referenced); dropped since it was dead code.
        def build(link_descendants, ancestor_id, document_id)
          ancestor_link = if ancestor_id.present?
                            @controller.catalog_url(ancestor_id.last)
                          else
                            @controller.catalog_url(document_id)
                          end
          
          Array(link_descendants).map do |item|
            {
              anchor: item[:href],
              collection: [{ href: ancestor_link, type: "text/html" }]
            }
          end
        end
      end
    end
  end
end
