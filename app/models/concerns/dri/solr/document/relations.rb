module DRI::Solr::Document::Relations

  def relationships_records
    records = {}

    object_class = self.active_fedora_model.constantize
    relationships = object_class.relationships

    relationships.each { |key, value| records[key] = retrieve_relation_records(self.object_profile[value[:field]], object_class.solr_relationships_field)}

    records
  end

  def retrieve_relation_records rels_array, solr_id_field
    records = []

    # Get Root collection of current object.
    # This is to restrict relationship processing only within the given collection
    solr_query = "id:\"#{id.to_s}\""
    # The query service returns back a set of Solr Documents, therefore need to be casted later on
    solr_docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

    if solr_docs.present?  
      doc = SolrDocument.new(solr_docs[0])
      root_collection = doc[ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)]

      if (root_collection)
        rels_array.each do |item_id|
          # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
          solr_query = "#{solr_id_field}:\"#{item_id.to_s}\""
          solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root_collection.first.to_s}\""
          solr_results = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

          if solr_results.empty?
            Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
          else
            solr_results.each do |item|
              doc = SolrDocument.new(item)
              records << doc.id
            end
          end
        end
      else
        Rails.logger.error("Root collection ID for object with PID #{self.id} not found in Solr")
      end

    else
      Rails.logger.error("Solr document for object with PID #{self.id} not found in Solr")
    end

    records
  end # end retrieve_rela

end