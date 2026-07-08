# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Builds the "item" links pointing at the direct children (objects
      # and/or sub-collections) of a collection document.
      class CollectionLinkBuilder
        def initialize(controller)
          @controller = controller
        end

        def build(document)
          # Direct children only - objects and subcollections of this
          # collection, not deeper descendants.
          document.children(chunk: 1000, sort: nil, subcollections_only: false).map do |child|
            {
              href: @controller.catalog_url(child.id),
              type: child.collection? ? "text/html" : child.mime_type
            }
          end
        end
      end
    end
  end
end
