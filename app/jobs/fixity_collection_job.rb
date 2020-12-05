class FixityCollectionJob
  @queue = :fixity

  def self.perform(report_id, collection_id, user_id)
    # start jobs for all sub-collections
    sub_collection_verify_jobs(report_id, collection_id)

    # verify direct child objects of this collection
    queue_job(report_id, collection_id, collection_id)
  end

  def self.sub_collection_verify_jobs(collection_id)
    q_str = "#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    f_query = "#{Solrizer.solr_name('is_collection', :facetable, type: :string)}:true"

    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.each { |subcoll| queue_job(report_id, collection_id, subcoll['id']) }
  end

  def self.queue_job(report_id, root_collection_id, collection_id)
    Resque.enqueue(FixityJob, report_id, root_collection_id, collection_id)
  end
end
