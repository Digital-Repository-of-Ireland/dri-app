class ReviewJob
  include Resque::Plugins::Status
  include DRI::Versionable

  def queue
    :review
  end

  def name
    'ReviewJob'
  end

  def perform
    collection_id = options['collection_id']
    user_id = options['user_id']
    user = UserGroup::User.find(user_id)

    set_status(collection_id: collection_id)

    # get objects within this collection, not including sub-collections
    q_str = "#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND status_ssi:draft"
    f_query = "is_collection_ssi:false"

    completed, failed = set_as_reviewed(collection_id, user, q_str, f_query)
    collection = DRI::Identifier.retrieve_object(collection_id)

    # Need to set sub-collection to reviewed
    if subcollection?(collection) && collection.status == 'draft'
      collection.status = 'reviewed'
      collection.increment_version

      failed += 1 unless collection.save

      record_version_committer(collection, user)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(collection)
      preservation.preserve
    end

    completed(completed: completed, failed: failed)
  end

  def set_as_reviewed(collection_id, user, q_str, f_query)
    total_objects = Solr::Query.new(q_str, 100, { fq: f_query }).count

    query = Solr::Query.new(q_str, 100, fq: f_query)

    completed = 0
    failed = 0

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = DRI::Identifier.retrieve_object(object['id'])
        if o && o.status == 'draft'
          o.status = 'reviewed'
          o.increment_version
          o.save ? (completed += 1) : (failed += 1)

          record_version_committer(o, user)

          # Do the preservation actions
          preservation = Preservation::Preservator.new(o)
          preservation.preserve
        end
      end

      unless total_objects.zero?
        at(completed, total_objects,
           "Reviewing #{collection_id}: #{completed} of #{total_objects} marked as reviewed")
      end
    end

    return completed, failed
  end

  def subcollection?(object)
    object.collection? && !object.root_collection?
  end
end
