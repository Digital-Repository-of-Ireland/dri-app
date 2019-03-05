require 'search_object/plugin/graphql'

module Resolvers
  class CollectionsSearch < BaseResolver
    # include SearchObject for GraphQL
    include SearchObject.module(:graphql)

    # scope is starting point for search
    scope do
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published'
      )
    end

    type types[Types::CollectionType]

    # inline input type definition for the advance filter
    class CollectionFilter < ::Types::BaseInputObject
      argument :OR, [self], required: false
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
      branches = normalize_filters(value).reduce { |a, b| a.or(b) }
      scope.merge branches
    end

    def normalize_filters(value, branches = [])
      scope = Link.all
      scope = scope.like(:description, value['description_contains']) if value['description_contains']

      branches << scope

      value['OR'].reduce(branches) { |s, v| normalize_filters(v, s) } if value['OR'].present?

      branches
    end
  end
end
