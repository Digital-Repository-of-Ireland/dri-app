module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :all_collections, [CollectionType], null: false,
      description: "All published collection"

    def all_collections
      # # still over fetching, and super slow call to fedora
      # ActiveFedora::Base.all.select(&:collection?)

      # # still overfetching, call to solr
      # app.get '/catalog.json?mode=collections'
      # response = app.response

      # # can't rely on object_type, it's use input
      # DRI::QualifiedDublinCore.where("Collection IN (#{object_type.join(', ')})",
      #   status: 'published'
      # ).all.count

      # # TODO more efficient where, select collection
      # # object_type is array, check it contains only 'collection'
      # DRI::QualifiedDublinCore.where(status: 'published').select do |qdc| 
      #   qdc.object_type.include?('Collection')
      # end


      # DRI::QualifiedDublinCore.where(status: 'published').select(&:collection?)

      collection_field = ActiveFedora.index_field_mapper.solr_name(
        'is_collection', :facetable, type: :string
      )
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published'
      )
    end
  end
end
