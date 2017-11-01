class FixityJob
  extend Preservation::PreservationHelpers

  @queue = :fixity
  
  def self.perform(collection_id)
    Rails.logger.info "Verifying collection #{collection_id}"
    
    # query for objects within this collection
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
   
    # excluding sub-collections
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    fixity_check(collection_id, q_str, f_query)
  end

  def self.fixity_check(collection_id, q_str, f_query)
    total_objects = ActiveFedora::SolrService.count(q_str, { fq: f_query })
    query = Solr::Query.new(q_str, 100, fq: f_query)
    
    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        result = verify(object['id'])
        
        FixityCheck.create(
          collection_id: collection_id,
          object_id: object['id'],
          verified: result.verified,
          result: result.to_json
        )
      end
    end

  end
end
