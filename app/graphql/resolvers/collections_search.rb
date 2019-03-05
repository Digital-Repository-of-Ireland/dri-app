require 'search_object/plugin/graphql'

module Resolvers
  class CollectionsSearch < BaseResolver
    # include SearchObject for GraphQL
    include SearchObject.module(:graphql)

    def all_collections(kwargs: {})
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published',
        **kwargs
      )
    end

    # scope is starting point for search
    scope do
      all_collections
    end

    type types[Types::CollectionType]

    # inline input type definition for the advance filter
    class CollectionFilter < ::Types::BaseInputObject
      argument :OR, [self], required: false
      argument :AND, [self], required: false
      # TODO dynamic args for filter, use CollectionType.fields
      argument :description_contains, String, required: false
    end

    # when "filter" is passed "apply_filter" would be called to narrow the scope
    option :filter, type: CollectionFilter, with: :apply_filter
    option :first, type: types.Int, with: :apply_first
    option :skip, type: types.Int, with: :apply_skip

    def apply_first(scope, value)
      scope.limit(value)
    end

    def apply_skip(scope, value)
      scope.offset(value)
    end

    # apply_filter recursively loops through "OR" branches
    def apply_filter(scope, value)
      # TODO: time / profile which is more efficient
      # modify results
      scope.where(*normalize_filters(value))

      # # new results
      # all_collections(normalize_filters(value))
    end

    # @param [Hash] value
    def normalize_filters(value)      
      value.map do |k, v|
        k = k.to_s
        raise ArgumentError, "Invalid query #{k}" unless valid_query?(k)
        field, query_type = k.split('_')
        send("#{query_type}_query", field, v)
      end
    end

    # @param [String] query
    # @return [Boolean]
    def valid_query?(query)
      return false unless query.count('_') == 1
      field, query_type = query.split('_')
      return false unless Types::CollectionType.fields.key?(field)
      return false unless %w[contains is].include?(query_type)
      return true      
    end
  end
end
