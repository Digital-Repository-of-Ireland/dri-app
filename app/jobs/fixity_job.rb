class FixityJob
  include Resque::Plugins::Status
  include Preservation::PreservationHelpers

  def queue
    :fixity
  end

  def name
    'FixityJob'
  end

  def perform
    collection_id = options['collection_id']
    
    Rails.logger.info "Verifying collection #{collection_id}"
    set_status(collection_id: collection_id)

    # query for objects within this collection
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
   
    # excluding sub-collections
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    completed, failed = fixity_check(collection_id, q_str, f_query)

    completed(completed: completed, failed: failed)
  end

  def fixity_check(collection_id, q_str, f_query)
    total_objects = ActiveFedora::SolrService.count(q_str, { fq: f_query })
    query = Solr::Query.new(q_str, 100, fq: f_query)

    completed = 0
    failed = 0

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
        
        if result.verified
          completed += 1
        else
          failed += 1
        end
      end

      unless total_objects.zero?
        at(completed, total_objects,
           "Verifying #{collection_id}: #{completed} of #{total_objects} completed")
      end
    end

    return completed, failed
  end
end
