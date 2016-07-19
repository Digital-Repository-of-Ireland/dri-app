class ReviewCollectionJob
  @queue = :review
    
  def self.perform(collection_id, user_id, uuid = nil)
    job_id = uuid || SecureRandom.uuid
 
    Rails.logger.info "Setting sub-collection objects in collection #{collection_id} to reviewed"

    q_str = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:draft"
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    # get all sub-collections
    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        Resque.enqueue(ReviewJob, subcoll['id'], user_id, uuid) 
      end
    end

    # review direct child objects of this collection
    Resque.enqueue(ReviewJob, collection_id, user_id, uuid) 
  end
end
