class ReviewCollectionJob
  def queue
    :review
  end

  def self.perform(collection_id, user_id)
    # get all sub-collections
    sub_collection_review_jobs(collection_id, user_id)

    # review direct child objects of this collection
    Resque.enqueue(ReviewJob, collection_id, user_id)
  end

  def self.sub_collection_review_jobs(collection_id, user_id)
    # need to include published and reviewed sub-collections in case new draft objects have been added
    q_str = "ancestor_id_ssim:\"#{collection_id}\""
    f_query = "is_collection_ssi:true"

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        Resque.enqueue(ReviewJob, subcoll['id'], user_id) 
      end
    end
  end
end
