require 'search_object/plugin/graphql'

module Resolvers
  class CollectionsSearch < BaseResolver
    include SearchObject.module(:graphql)

    # TODO: migrate to ActiveFedora::SolrService.query ?
    def all_collections(kwargs: {})
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published',
        **kwargs
      )
    end

    scope do
      all_collections
    end

    type types[Types::CollectionType]

    # inline input type definition for the advance filter
    class CollectionFilter < ::Types::BaseInputObject
      argument :OR, [self], required: false
      argument :AND, [self], required: false
      # argument :description_contains, String, required: false
      Types::CollectionType.fields.keys.each do |field_name|
        argument :"#{field_name.underscore}_contains", String, required: false
        argument :"#{field_name.underscore}_is", String, required: false
      end
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

    # TODO: iteratively generate and / or solr queries
    def apply_filter(scope, value)
      # TODO: time / profile which is more efficient
      # modify results
      scope.where(*query_array(value))

      # # new results
      # all_collections(kwargs: query_hash(value))
    end

    # @param [Hash] value
    # @return [hash]
    def query_hash(value)
      # TODO: just merge the hashes instead of converting to array and back
      value.map do |k, v|
        k = k.to_s
        # split on last occurrence of _
        field, _, query_type = k.rpartition('_')        
        send("#{query_type}_query_hash", field, v).to_a.first
      end.to_h
    end

    # @param [Hash] value
    # @return [Array] array of strings
    def query_array(value)
      value.map do |k, v|
        k = k.to_s
        # split on last occurrence of _
        field, _, query_type = k.rpartition('_')
        send("#{query_type}_query", field, v)
      end
    end
  end
end
