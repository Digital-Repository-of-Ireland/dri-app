# frozen_string_literal: true

module DRI
  module AccessControls
    # Builds the flat list of jsTree-style entries - and nests them into
    # a hierarchy - used to render the access-controls management tree
    # for a collection and its descendants.
    class TreeBuilder
      def self.entries_for(collections)
        new(collections).entries
      end

      # Nests a flat list of {id:, parent_id:, ...} entries into a tree,
      # adding a :children array to each and returning only the
      # top-level (parent_id nil) entries.
      def self.nest(entries)
        by_id = entries.each_with_object({}) { |entry, hash| hash[entry[:id]] = entry.merge(children: []) }

        by_id.each_value do |item|
          parent = by_id[item[:parent_id]]
          parent[:children] << item if parent
        end

        by_id.values.select { |item| item[:parent_id].nil? }
      end

      def initialize(collections)
        @collections = collections
      end

      def entries
        collections.flat_map { |document| entries_for_document(document) }
      end

      private

      attr_reader :collections

      def entries_for_document(document)
        id = document.id
        permissions = PermissionsSummary.for(document)
        inherited_count = CollectionPermissions.count_with_inherited_permissions(document)
        custom_objects = CollectionPermissions.with_custom_permissions(document)

        entries = [folder_entry(document, id, permissions)]
        entries << inherited_summary_entry(document, id, inherited_count) if inherited_count.positive?
        entries << custom_summary_entry(id, custom_objects) if custom_objects.size.positive?
        entries.concat(custom_object_entries(id, custom_objects))
        entries
      end

      def folder_entry(document, id, permissions)
        parents = document['ancestor_id_ssim']

        {
          id: id,
          type: 'folder',
          text: "#{document['title_tesim'].first}: #{permissions[:read_label]} #{permissions[:assets_label]}",
          dataAttributes: {
            'data-read' => permissions[:read_access],
            'data-assets' => permissions[:assets]
          },
          parent_id: parents.nil? ? nil : parents.first
        }
      end

      def inherited_summary_entry(document, id, count)
        {
          id: "#{id}-inherit",
          type: 'item',
          text: I18n.t('dri.views.objects.access_controls.inherit_objects', count: count),
          icon: 'glyphicon glyphicon-info-sign',
          parent_id: document.id
        }
      end

      def custom_summary_entry(id, custom_objects)
        {
          id: "#{id}-custom",
          type: 'folder',
          text: I18n.t('dri.views.objects.access_controls.custom_objects', count: custom_objects.size),
          icon: 'glyphicon glyphicon-info-sign',
          parent_id: id
        }
      end

      def custom_object_entries(id, custom_objects)
        custom_objects.map do |object|
          permissions = PermissionsSummary.for(object)

          {
            id: object.id.to_s,
            type: 'item',
            text: "#{object['title_tesim'].first}: #{permissions[:read_label]} #{permissions[:assets_label]}",
            icon: 'glyphicon glyphicon-file',
            dataAttributes: {
              'data-read' => permissions[:read_access],
              'data-assets' => permissions[:assets]
            },
            parent_id: "#{id}-custom"
          }
        end
      end
    end
  end
end
