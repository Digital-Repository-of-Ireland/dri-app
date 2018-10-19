class PublishJob
  include Resque::Plugins::Status

  def queue
    :publish
  end

  def name
    'PublishJob'
  end

  def perform
    collection_id = options['collection_id']

    Rails.logger.info "Publishing collection #{collection_id}"
    set_status(collection_id: collection_id)

    # query for reviewed objects within this collection
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:reviewed"

    # excluding sub-collections
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    completed, failed = set_as_published(collection_id, q_str, f_query)

    collection = ActiveFedora::Base.find(collection_id, cast: true)

    # if already published skip
    return if collection.status == 'published'

    # publish the collection object and mint a DOI
    collection.status = 'published'
    collection.published_at = Time.now.utc.iso8601
    version = collection.object_version || '1'
    collection.object_version = (version.to_i + 1).to_s
    if collection.save
      mint_doi(collection)

      # Do the preservation actions
      preservation = Preservation::Preservator.new(collection)
      preservation.preserve(false, false, ['properties'])
    else
      failed += 1
    end

    completed(completed: completed, failed: failed)
  end

  def set_as_published(collection_id, q_str, f_query)
    total_objects = ActiveFedora::SolrService.count(q_str, { fq: f_query })

    query = Solr::Query.new(q_str, 100, fq: f_query)

    completed = 0
    failed = 0

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object['id'], { cast: true })

        next unless o.status == 'reviewed'
        o.status = 'published'
        version = o.object_version || '1'
        o.object_version = (version.to_i + 1).to_s

        if o.save
          completed += 1
          mint_doi(o)

          # Do the preservation actions
          preservation = Preservation::Preservator.new(o)
          preservation.preserve(false, false, ['properties'])
        else
          failed += 1
        end
      end

      unless total_objects.zero?
        at(completed, total_objects,
           "Publishing #{collection_id}: #{completed} of #{total_objects} marked as published")
      end
    end

    return completed, failed
  end

  def mint_doi(obj)
    return if Settings.doi.enable != true || DoiConfig.nil?

    if obj.descMetadata.has_versions?
      DataciteDoi.create(
        object_id: obj.id,
        modified: 'DOI created',
        mod_version: obj.descMetadata.versions.last.uri
      )
    else
      DataciteDoi.create(object_id: obj.id, modified: 'DOI created')
    end

      DRI.queue.push(MintDoiJob.new(obj.id))
  rescue Exception => e
    Rails.logger.error "Unable to submit mint doi job: #{e.message}"
  end
end
