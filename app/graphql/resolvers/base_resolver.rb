require 'search_object/plugin/graphql'

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    include Helpers::SolrHelper
    include SearchObject.module(:graphql)

    # @param [ActiveFedora::Relation] scope
    # @param [Integer] value
    # @return [ActiveFedora::Relation]
    def apply_first(scope, value)      
      scope.limit(value)
    end

    # @param [ActiveFedora::Relation] scope
    # @param [Integer] value
    # @return [ActiveFedora::Relation]
    def apply_skip(scope, value)
      scope.offset(value)
    end

    # @param [ActiveFedora::Relation] scope
    # @param [Hash] value
    # @return [ActiveFedora::Relation]
    def apply_filter(scope, value)      
      # TODO: iteratively generate and / or solr queries

      # generate chain of .where calls for every arg from graphql e.g.
      # ['is_collection_sim:true', 'status_sim:published'].reduce(DRI::QualifiedDublinCore) { |cls, arg| cls.where(arg) }
      query_array(value).reduce(scope) do |scp, arg|
        scp.where(arg)
      end

    end
  end
end
