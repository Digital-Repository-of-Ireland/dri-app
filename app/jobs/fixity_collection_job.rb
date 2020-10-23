class FixityCollectionJob
  @queue = :fixity

  def self.perform(collection_id, user_id)
    report = FixityReport.create(collection_id: collection_id)

    # start jobs for all sub-collections
    sub_collection_verify_jobs(report, collection_id)

    # verify direct child objects of this collection
    queue_job(report, collection_id)
  end

  def self.sub_collection_verify_jobs(report, collection_id)
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    job_ids = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each { |subcoll| queue_job(report, subcoll['id']) }
    end
  end

  def self.queue_job(report, collection_id)
    Resque.enqueue(FixityJob, report.id, collection_id)
  end
end
