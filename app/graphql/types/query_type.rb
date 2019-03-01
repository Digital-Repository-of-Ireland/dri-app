module Types
  class QueryType < Types::BaseObject
    field :all_collections, [CollectionType], null: false,
          description: "All published collections"
    # field :all_objects, [ObjectType], null: false,
    #       description: "All published objects"

    def all_collections
      collection_field = ActiveFedora.index_field_mapper.solr_name(
        'is_collection', :facetable, type: :string
      )
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published'
      )
    end

    # def all_objects
    #   # # no object field, closest is !collection? && batch?
    #   # # see app/models/solr_document.rb#object?
    #   # collection_field = ActiveFedora.index_field_mapper.solr_name(
    #   #   'is_collection', :facetable, type: :string
    #   # )
    #   # # DRI::QualifiedDublinCore.where(status: 'published').where.not("#{collection_field}": 'true').where('DRI::Batch IN has_model_ssim')
    #   # DRI::QualifiedDublinCore.where("#{collection_field} NOT IN (?)", %w[true]) 


    #   DRI::QualifiedDublinCore.where(status: 'published').select(&:object?)
    # end
  end
end
