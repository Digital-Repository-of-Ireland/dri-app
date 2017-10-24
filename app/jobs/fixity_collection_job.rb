class FixityCollectionJob < StatusJob
  def queue
    :fixity
  end

  def name
    'FixityCollectionJob'
  end

  def perform
    collection_id = options['collection_id']
    user_id = options['user_id']

    # start jobs for all sub-collections
    job_ids = sub_collection_verify_jobs(collection_id, user_id)

    # verify direct child objects of this collection
    job_ids << FixityJob.create(collection_id: collection_id, user_id: user_id)
    failures = wait_for_completion(collection_id, job_ids)

    message = "Completed verifying collection #{collection_id}."
    message += "Failed to verify #{failures} objects." if failures > 0
    completed(message)
  end

  def sub_collection_verify_jobs(collection_id, user_id)
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    job_ids = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        job_id = FixityJob.create(collection_id: subcoll['id'], user_id: user_id)
        job_ids << job_id
      end
    end

    job_ids
  end

  def update(identifier, total, completed)
    at(completed, total,
        "Verifying #{identifier}: #{completed} of #{total} sub-collections completed")
  end
end
