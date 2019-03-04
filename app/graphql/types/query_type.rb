module Types
  class QueryType < Types::BaseObject
    # TODO: handle access levels, currently only published
    # TODO: add default limit, querying everything in production will be very resource intensive / slow
    # e.g. DRI::QualifiedDublinCore.where(status: 'published').limit(10)

    field :all_collections, [CollectionType], null: false,
          description: "All published collections"
    field :all_objects, [ObjectType], null: false,
          description: "All published objects"

    def all_collections
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'true',
        status: 'published'
      )
    end

    def all_objects
      # # no object field, closest is !collection? && batch?
      # # see app/models/solr_document.rb#object?
      # # 
      # # can't rely on object_type since it's set by user input
      # # what about file_type? (file_type_sim) method alias object#type
      # # what about has_model?
      # # catalog and my_collections controllers use not collection and exclude generic files
      # # see app/controllers/concerns/dri/catalog.rb

      # collection_field = ActiveFedora.index_field_mapper.solr_name(
      #   'is_collection', :facetable, type: :string
      # )
      # # DRI::QualifiedDublinCore.where(status: 'published').where.not("#{collection_field}": 'true').where('DRI::Batch IN has_model_ssim')
      # DRI::QualifiedDublinCore.where("#{collection_field} NOT IN (?)", %w[true]) 

      # # too slow
      # DRI::QualifiedDublinCore.where(status: 'published').select(&:object?)
      DRI::QualifiedDublinCore.where(
        "#{collection_field}": 'false',
        # "#{generic_file_field}": 'DRI::GenericFile'
        status: 'published'
      )
    end

    private

      def collection_field
        ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)
      end

      def generic_file_field
        # Solr::SchemaFields.searchable_symbol('has_model')}:\"DRI::GenericFile\"
        ActiveFedora.index_field_mapper.solr_name('has_model')
      end

      ## Example queries 
      ########################################
      # query getAllPublishedCollections {
      #   allCollections {
      #     id, publishedAt, createDate, modifiedDate,
          
      #     title, creator,
          
      #     depositingInstitute,
          
      #     licence, language, contributor, publishedDate, relation, 
      #     coverage, temporalCoverage, geographicalCoverage, subject,
      #     qdcId
      #   }
      # }

      # query getAllPublishedObjects {
      #   allObjects {
      #     id
      #   }
      # }
  end
end
