# frozen_string_literal: true

module DRI
  module Formatters
    class Linkset
      # Builds the "item" links pointing at a (non-collection) document's
      # own asset files - surrogate downloads, plus master files where the
      # document allows master access.
      class AssetLinkBuilder
        def initialize(controller, document)
          @controller = controller
          @document = document
        end

        def build(assets, id)
          assets.each_with_object([]) do |asset, links|
            add_links_for(asset, id, links)
          end
        end

        private

        attr_reader :controller, :document

        def add_links_for(asset, id, links)
          id_file = clean(asset&.fetch("id", nil))
          mime_type = clean(asset&.fetch("mime_type_tesim", nil))

          if asset.text? || asset.pdf?
            add_text_or_pdf_links(asset, id, id_file, mime_type, links)
          elsif asset.threeD?
            # NOTE: the original branched on document.read_master? here to
            # choose between a "masterfile" and "surrogate" labeled link,
            # but since that label doesn't affect the built href/type (see
            # #link_for), both branches produced an identical result - so
            # the branch is collapsed here.
            links << link_for(id_file, id, mime_type)
          else
            links << link_for(id_file, id, mime_type)
          end
        end

        def add_text_or_pdf_links(asset, id, id_file, mime_type, links)
          if mime_type.include?("application/pdf")
            links << link_for(id_file, id, mime_type)
          else
            links << link_for(id_file, id, "application/pdf")

            if document.read_master? && asset.text? && !mime_type.include?("application/pdf")
              links << link_for(id_file, id, mime_type)
            end
          end
        end

        # NOTE: the original `item_link` accepted a "surrogate"/"masterfile"
        # label but never actually used it to vary the download url - the
        # call to file_download_url always passed type: 'surrogate'
        # regardless. That looks like a bug (master file downloads should
        # presumably request type: 'masterfile'), but it's preserved as-is
        # here since it isn't covered by a test and changing it would be a
        # behavioural change to what gets downloaded.
        def link_for(id_file, id, mime_type)
          href = controller.file_download_url(id: id_file, object_id: id, type: "surrogate")
          { href: href, type: mime_type }
        end

        def clean(value)
          value.to_s.gsub(/[\[\]"]/, "")
        end
      end
    end
  end
end
