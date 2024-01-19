class PublishCollectionJob
  def queue
    :publish
  end
  
  def self.perform(collection_id, user_id)
    # start jobs for all sub-collections
    sub_collection_publish_jobs(collection_id, user_id)

    # review direct child objects of this collection
    Resque.enqueue(PublishJob, collection_id, user_id)
  end

  def self.sub_collection_publish_jobs(collection_id, user_id)
    # sub-collections that are not draft (need to include published to allow for iterative publishing
    # i.e., publishing of reviewed objects added to already published collections)
    q_str = "ancestor_id_ssim:\"#{collection_id}\""
    q_str += " AND -status_ssi:draft"

    f_query = "is_collection_ssi:true"

    job_ids = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        Resque.enqueue(PublishJob, subcoll['id'], user_id)
      end
    end
  end
end
