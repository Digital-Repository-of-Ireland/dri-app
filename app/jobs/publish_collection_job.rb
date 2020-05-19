class PublishCollectionJob < StatusJob
  def queue
    :publish
  end

  def name
    'PublishCollectionJob'
  end

  def perform
    collection_id = options['collection_id']
    user_id = options['user_id']

    # start jobs for all sub-collections
    job_ids = sub_collection_publish_jobs(collection_id, user_id)

    # review direct child objects of this collection
    job_ids << PublishJob.create(collection_id: collection_id, user_id: user_id)
    failures = wait_for_completion(collection_id, job_ids)

    message = "Completed marking collection #{collection_id} as published."
    message += "Unable to set status for #{failures} objects." if failures > 0
    completed(message)
  end

  def sub_collection_publish_jobs(collection_id, user_id)
    # sub-collections that are not draft (need to include published to allow for iterative publishing
    # i.e., publishing of reviewed objects added to already published collections)
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND -#{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:draft"

    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    job_ids = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        job_id = PublishJob.create(collection_id: subcoll['id'], user_id: user_id)
        job_ids << job_id
      end
    end

    job_ids
  end

  def update(identifier, total, completed)
    at(completed, total,
        "Publishing #{identifier}: #{completed} of #{total} sub-collections marked as published")
    UserBackgroundTask.find_by(job: uuid).try(:update)
  end
end
