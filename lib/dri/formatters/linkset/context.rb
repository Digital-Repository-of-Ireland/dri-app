# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Gathers every piece of data needed to render a linkset for a
      # document, exactly once, so the lset and json renderers can each
      # just format the same data rather than recomputing it twice (as the
      # original #lset and #json methods each did independently).
      class Context
        attr_reader :controller, :document, :anchor_url, :doi, :schema_link,
                    :orcid_links, :license_link, :copyright_link,
                    :link_descendants, :describedby, :reverse_link

        def initialize(controller, document)
          @controller = controller
          @document = document

          @anchor_url = controller.catalog_url(document.id)
          @doi = DoiLookup.resolve(document)
          @schema_link = SchemaTypeMapper.lookup(document.type)
          @orcid_links = ContributorLinks.for(document)
          @license_link = LicenceLink.for(document)
          @copyright_link = document.copyright&.url

          @link_descendants = if document.collection?
                                 CollectionLinkBuilder.new(controller).build(document)
                               else
                                 AssetLinkBuilder.new(controller, document).build(document.assets, document.id)
                               end

          @describedby = MetadataLinkBuilder.new(controller).build(document)

          # 'isGovernedBy_ssim' links objects to a sub-collection;
          # 'ancestor_id_ssim' escapes the sub-collection.
          ancestor_id = document["isGovernedBy_ssim"] || document["ancestor_id_ssim"]
          @reverse_link = ReverseLinkBuilder.new(controller).build(@link_descendants, ancestor_id, document.id)
        end
      end
    end
  end
end
