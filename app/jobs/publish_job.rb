class PublishJob
  include DRI::Versionable

  @queue = :publish

  def self.perform(collection_id, user_id)
    user = UserGroup::User.find(user_id)

    Rails.logger.info "Publishing collection #{collection_id}"

    # query for reviewed objects within this collection
    q_str = "collection_id_sim:\"#{collection_id}\""
    q_str += " AND status_ssi:reviewed"

    # excluding sub-collections
    f_query = "is_collection_ssi:false"

    completed, failed = set_as_published(collection_id, user, q_str, f_query)

    ident = DRI::Identifier.find_by!(alternate_id: collection_id)
    collection = ident.identifiable

    # if already published skip
    return if collection.status == 'published'

    # publish the collection object and mint a DOI
    collection.status = 'published'
    collection.published_at = Time.now.utc.iso8601
    collection.object_version ||= '1'
    collection.increment_version
    doi = create_doi(collection)
    collection.doi = doi.doi if doi

    if collection.save
      mint_doi(doi) if doi

      VersionCommitter.create(
        version_id: 'v%04d' % collection.object_version,
        obj_id: collection.alternate_id,
        committer_login: user.to_s,
        event: 'published'
      )

      # Do the preservation actions
      preservation = Preservation::Preservator.new(collection)
      preservation.preserve
    else
      doi.destroy if doi
    end
  end

  def self.set_as_published(collection_id, user, q_str, f_query)
    total_objects = Solr::Query.new(q_str, 100, { fq: f_query }).count

    query = Solr::Query.new(q_str, 100, fq: f_query)

    completed = 0
    failed = 0

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = DRI::DigitalObject.find_by_alternate_id(object['alternate_id'])

        next unless o.status == 'reviewed'
        o.status = 'published'
        o.published_at = Time.now.utc.iso8601
        o.object_version ||= '1'
        o.increment_version

        doi = create_doi(o)
        o.doi = doi.doi if doi

        if o.save
          VersionCommitter.create(
            version_id: 'v%04d' % o.object_version,
            obj_id: o.alternate_id,
            committer_login: user.to_s,
            event: 'published'
          )

          # Do the preservation actions
          preservation = Preservation::Preservator.new(o)
          preservation.preserve
          mint_doi(doi) if doi
        else
          doi.destroy if doi
        end
      end
    end
  end

  def self.create_doi(obj)
    return if Settings.doi.enable != true || DoiConfig.nil?

    DataciteDoi.find_or_create_by(
      object_id: obj.alternate_id,
      modified: 'DOI created',
      mod_version: obj.object_version
    )
  end

  def self.mint_doi(doi)
    return if Settings.doi.enable != true || DoiConfig.nil?

    Resque.enqueue(MintDoiJob, doi.id)
  rescue Exception => e
    Rails.logger.error "Unable to submit mint doi job: #{e.message}"
  end
end
