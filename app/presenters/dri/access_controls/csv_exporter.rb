# frozen_string_literal: true

module DRI
  module AccessControls
    # Builds the CSV access-controls report for a collection and its
    # descendants: one row per object (not per collection) that either
    # inherits or has custom access permissions.
    class CsvExporter
      HEADERS = ['collection', 'title', 'users', 'asset file access'].freeze

      def self.generate(collections)
        new(collections).generate
      end

      def initialize(collections)
        @collections = collections
      end

      def generate
        CSV.generate(headers: true) do |csv|
          csv << HEADERS

          collections.each do |collection|
            objects_for(collection).each do |object|
              csv << row_for(collection, object)
            end
          end
        end
      end

      private

      attr_reader :collections

      def objects_for(collection)
        CollectionPermissions.with_inherited_permissions(collection) + CollectionPermissions.with_custom_permissions(collection)
      end

      def row_for(collection, object)
        permissions = PermissionsSummary.for(object)

        [
          collection['title_tesim'].first,
          object['title_tesim'].first,
          permissions[:read_access],
          permissions[:assets_label]
        ]
      end
    end
  end
end
