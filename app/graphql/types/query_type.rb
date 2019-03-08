module Types
  class QueryType < Types::BaseObject
    # TODO: handle access levels, currently only published, add user scope
    # TODO: add default limit, querying everything in production will be very resource intensive / slow
    # e.g. DRI::QualifiedDublinCore.where(status: 'published').limit(10)

    field :all_collections, [CollectionType], null: false,
          description: "All published collections", function: Resolvers::CollectionsSearch
    field :all_objects, [ObjectType], null: false,
          description: "All published objects"

    # could refactor to use enum option to specify type?
    # .e.g search(type:collection) instead of CollectionsSearch

    def all_objects
      # # no object field, closest is !collection? && batch?
      # # see app/models/solr_document.rb#object?
      # # 
      # # can't rely on object_type since it's set by user input
      # # what about file_type? (file_type_sim) method alias object#type
      # # what about has_model?
      # # catalog and my_collections controllers use not collection and exclude generic files
      # # see app/controllers/concerns/dri/catalog.rb

      collection_field = Solr::SchemaFields.facet('is_collection')
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'false',
        # "#{generic_file_field}": 'DRI::GenericFile'
        status: 'published'
      )
    end
  end
end
