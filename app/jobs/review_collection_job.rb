class ReviewCollectionJob
  include Resque::Plugins::Status

  def queue
    :review
  end

  def name
    'ReviewCollectionJob'
  end
    
  def perform
    collection_id = options['collection_id']
    user_id = options['user_id']

    # get all sub-collections
    job_ids = sub_collection_review_jobs(collection_id, user_id)

    # review direct child objects of this collection
    job_ids << ReviewJob.create(collection_id: collection_id, user_id: user_id) 
    failures = wait_for_completion(collection_id, job_ids)
    
    message = "Completed marking collection #{collection_id} as reviewed."
    message += "Unable to set status for #{failures} objects." if failures > 0
    completed(message)
  end

  def sub_collection_review_jobs(collection_id, user_id)
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:draft"
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    job_ids = []

    query = Solr::Query.new(q_str, 100, fq: f_query)
    while query.has_more?
      subcollection_objects = query.pop

      subcollection_objects.each do |subcoll|
        job_id = ReviewJob.create(collection_id: subcoll['id'], user_id: user_id)
        job_ids << job_id
      end
    end

    job_ids
  end

  def wait_for_completion(collection_id, job_ids)
    return 0 unless job_ids.any?

    total_jobs = job_ids.length
    running_jobs = total_jobs
    
    completed = 0
    failures = 0
    job_statuses = {}

    while running_jobs > 0
      job_statuses = retrieve_status(job_ids)

      job_statuses.each do |job_id, status|
        if %w(completed failed killed).include?(status.status)
          completed += 1
          job_ids.delete(job_id)
          running_jobs -= 1
          
          failures += status['failed'] if status['failed'].present?
        end

        at(completed, total_jobs, 
          "Reviewing #{collection_id}: #{completed} of #{total_jobs} sub-collections marked as reviewed"
        )
      end  
    end

    failures
  end

  def retrieve_status(job_ids)
    statuses = {}

    job_ids.each { |job| statuses[job] = Resque::Plugins::Status::Hash.get(job) }
    
    statuses  
  end

end
