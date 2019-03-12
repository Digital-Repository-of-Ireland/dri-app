module Types
  class QueryType < Types::BaseObject
    # TODO: handle access levels, currently only published, add user scope
    # TODO: add default limit, querying everything in production will be very resource intensive / slow
    # e.g. DRI::QualifiedDublinCore.where(status: 'published').limit(10)

    field :all_collections, [CollectionType], null: false,
          description: "All published collections", function: Resolvers::CollectionsSearch
    field :all_objects, [ObjectType], null: false,
          description: "All published objects", function: Resolvers::ObjectsSearch

    # could refactor to use enum option to specify type?
    # .e.g search(type:collection) instead of CollectionsSearch
  end
end
