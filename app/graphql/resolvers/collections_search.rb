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
      # argument :OR, [self], required: false
      # argument :AND, [self], required: false
      Types::CollectionType.fields.keys.each do |field_name|
        argument :"#{field_name.underscore}_contains", String, required: false
        argument :"#{field_name.underscore}_is", String, required: false
        # TODO: escape solr chars for _is query? e.g. description_is:*test*
      end
    end

    option :filter, type: CollectionFilter, with: :apply_filter
    option :first, type: types.Int, 
                   default: blacklight_config.default_per_page, 
                   with: :apply_first
    option :skip, type: types.Int, with: :apply_skip

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
      # TODO: time / profile which is more efficient
      # modify results
      # will fail for filters with more than one value, need to chain where calls
      # scope.where(*query_array(value))
      query_array(value).reduce(scope) do |scp, arg|
        scp.where(arg)
      end

      # ['is_collection_sim:true', 'status_sim:published'].reduce(DRI::QualifiedDublinCore) { |cls, arg| cls.where(arg) }.length
      # [[:where, 'is_collection_sim:true'],[:where, 'status_sim:published']].reduce(DRI::QualifiedDublinCore) { |cls, (m, arg)| cls.send(m, arg) }.length

      # # new results
      # # fails for some cases, e.g. contributor
      # # DRI::QulaifiedDublinCore.where(contributor_sim: '*filter_test*').count # 1
      # # DRI::QulaifiedDublinCore.where("contributor_sim:*filter*").count     # 2
      # all_collections(kwargs: query_hash(value))
    end
  end
end
