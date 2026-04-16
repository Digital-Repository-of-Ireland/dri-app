class UpdateDescendantsJob
  @queue = :update
  
  def self.perform(collection_id)
    # start jobs for all sub-collections
    sub_collection_update_jobs(collection_id)

    # review direct child objects of this collection
    Resque.enqueue(UpdateGovernedItemsJob, collection_id)
  end

  def self.sub_collection_update_jobs(collection_id)
    q_str = "ancestor_id_ssim:\"#{collection_id}\""
    f_query = "is_collection_ssi:true"

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        Resque.enqueue(UpdateGovernedItemsJob, subcoll['id'])
      end
    end
  end
end