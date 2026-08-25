# frozen_string_literal: true

module DRI
  module Formatters
    # Builds a Signposting-style "linkset" for a document, describing its
    # DOI, schema.org type, authors (ORCID), licence/copyright, descendant
    # items (assets or collection children), metadata link, and reverse
    # collection links - rendered either as the RFC 9264 "lset" line
    # format or as JSON.
    #
    # This class is kept as a thin orchestrator: field-mapping-ish
    # concerns each live in their own collaborator class under
    # app/models/dri/formatters/linkset/. Every method that existed on the
    # original class is preserved here (as a delegating wrapper) so
    # existing callers keep working unchanged.
    class Linkset
      require "json"

      def initialize(controller, document, options = {})
        @controller = controller
        @document = document
      end

      def format(options = {})
        output_format = options[:format].presence || :lset
        output_format == :lset ? lset : json
      end

      def lset
        LsetRenderer.new(context).render
      end

      def json
        JsonRenderer.new(context).render
      end

      # --- Backward-compatible wrappers around the extracted collaborators ---

      def mapped_links(target_types, map = SchemaTypeMapper::SCHEMA_TYPES)
        SchemaTypeMapper.lookup(target_types, map)
      end

      def contributors
        ContributorLinks.for(@document)
      end

      def collection_objects
        CollectionLinkBuilder.new(@controller).build(@document)
      end

      def object_items(assets, id)
        AssetLinkBuilder.new(@controller, @document).build(assets, id)
      end

      def document_licence_link
        LicenceLink.for(@document)
      end

      def metadata_link
        MetadataLinkBuilder.new(@controller).build(@document)
      end

      def reverse_link_builder(link_descendants, ancestor_id, object_id)
        ReverseLinkBuilder.new(@controller).build(link_descendants, ancestor_id, object_id)
      end

      private

      def context
        Context.new(@controller, @document)
      end
    end
  end
end
