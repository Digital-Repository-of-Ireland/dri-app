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

    wait_for_completion(job_ids)
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

  def wait_for_completion(job_ids)
    return unless job_ids.any?

    total_jobs = job_ids.length
    
    job_statuses = {}

    while true
      job_statuses = retrieve_status(job_ids)
      completed_jobs = total_jobs - job_statuses.length
      at(completed_jobs, total_jobs, "#{completed_jobs} of #{total_jobs} completed!")
      
      status_codes = job_statuses.values
      break unless status_codes.include?('queued') || status_codes.include?('working')
    end
  end

  def retrieve_status(job_ids)
    statuses = {}
    job_ids.each_with_index do |job, index|
      status = Resque::Plugins::Status::Hash.get(job)

      state = status.status
      if %w(completed failed).include?(state)
        job_ids.delete(index)
      else
        statuses[job] = state
      end
    end

    statuses  
  end

end
