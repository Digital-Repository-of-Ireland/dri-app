module Resolvers
  class ObjectsSearch < BaseResolver
    # TODO: migrate to ActiveFedora::SolrService.query ?
    def all_objects(kwargs: {})
      # # no object field, closest is !collection? && batch?
      # # see app/models/solr_document.rb#object?
      # # 
      # # can't rely on object_type since it's set by user input
      # # what about file_type? (file_type_sim) method alias object#type
      # # what about has_model?
      # # catalog and my_collections controllers use not collection and exclude generic files
      # # no need to exclude generic files if add_referencing QualifiedDublinCore though
      # # see app/controllers/concerns/dri/catalog.rb
      
      # # false not the same as not true
      # # find cases where item is type object, but does not have is_collection_sim: false
      # # not clause doesn't work with active fedora unless some other clause at start
      # ['*:* !is_collection_sim:true', 'is_collection_sim:false'].map do |field|
      #   DRI::QualifiedDublinCore.where(field).length
      # end

      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'false',
        status: 'published',
        **kwargs
      )

      # # fq = %w[EXCLUDE_COLLECTIONS, EXCLUDE_GENERIC_FILES, PUBLISHED_ONLY].map! { |v| DRI::Catalog.const_get(v) }
      # fq = [DRI::Catalog::EXCLUDE_COLLECTIONS, DRI::Catalog::EXCLUDE_GENERIC_FILES, DRI::Catalog::PUBLISHED_ONLY]
      # ActiveFedora::SolrService.query('*:*', fq: fq)

      # # try to get limit from kwargs, if it's missing get default_per_page
      # limit = kwargs.dig(:limit) || blacklight_config.default_per_page

      # results = ActiveFedora::SolrService.query('*:*', fq: fq, rows: limit.to_s)
      # results.map { |doc| SolrDocument.new(doc) }
    end

    scope do
      all_objects
    end

    type types[Types::ObjectType]

    # inline input type definition for the advance filter
    class ObjectFilter < ::Types::BaseInputObject
      # argument :OR, [self], required: false
      # argument :AND, [self], required: false
      Types::ObjectType.fields.keys.each do |field_name|
        argument :"#{field_name.underscore}_contains", String, required: false
        argument :"#{field_name.underscore}_is", String, required: false
        # TODO: escape solr chars for _is query? e.g. description_is:*test*
      end
    end

    option :filter, type: ObjectFilter, with: :apply_filter
    option :first, type: types.Int, 
                   default: blacklight_config.default_per_page, 
                   with: :apply_first
    option :skip, type: types.Int, with: :apply_skip

  end
end
