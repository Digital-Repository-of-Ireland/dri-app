class ReviewJob
  include DRI::Versionable

  @queue = :review

  def self.perform(collection_id, user_id)
    user = UserGroup::User.find(user_id)

    # get objects within this collection, not including sub-collections
    q_str = "#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND status_ssi:draft"
    f_query = "is_collection_ssi:false"

    set_as_reviewed(collection_id, user, q_str, f_query)
    collection = DRI::Identifier.retrieve_object(collection_id)

    # Need to set sub-collection to reviewed
    if subcollection?(collection) && collection.status == 'draft'
      collection.status = 'reviewed'
      collection.increment_version

      failed += 1 unless collection.save

      VersionCommitter.create(version_id: 'v%04d' % collection.object_version, obj_id: collection.alternate_id, committer_login: user.to_s)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(collection)
      preservation.preserve
    end
  end

  def self.set_as_reviewed(collection_id, user, q_str, f_query)
    total_objects = Solr::Query.new(q_str, 100, { fq: f_query }).count

    query = Solr::Query.new(q_str, 100, fq: f_query)

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = DRI::Identifier.retrieve_object(object['id'])
        if o && o.status == 'draft'
          o.status = 'reviewed'
          o.increment_version
          o.save

          VersionCommitter.create(version_id: 'v%04d' % o.object_version, obj_id: o.alternate_id, committer_login: user.to_s)

          # Do the preservation actions
          preservation = Preservation::Preservator.new(o)
          preservation.preserve
        end
      end
    end
  end

  def self.subcollection?(object)
    object.collection? && !object.root_collection?
  end
end
