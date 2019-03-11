module Resolvers
  class CollectionsSearch < BaseResolver
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

  end
end
