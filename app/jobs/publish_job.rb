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
    user_id = options['user_id']

    Rails.logger.info "Publishing collection #{collection_id}"
    set_status(collection_id: collection_id)
    
    # query for reviewed objects within this collection
    q_str = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""   
    q_str += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:reviewed"

    # excluding sub-collections
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    query = Solr::Query.new(q_str)

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object['id'], cast: true)

        if o.status == 'reviewed'
          o.status = 'published'
          o.published_at = Time.now.utc.iso8601
          o.save

          mint_doi(o)
        end
      end
    end

    collection = ActiveFedora::Base.find(collection_id, cast: true)

    # if already published skip
    return if collection.status == 'published'

    # publish the collection object and mint a DOI
    collection.status = 'published'
    collection.published_at = Time.now.utc.iso8601
    collection.save

    mint_doi(collection)
  end

  def mint_doi(obj)
    return if Settings.doi.enable != true || DoiConfig.nil?

    if obj.descMetadata.has_versions?
      DataciteDoi.create(object_id: obj.id, 
        modified: 'DOI created', 
        mod_version: obj.descMetadata.versions.last.uri)
    else
      DataciteDoi.create(object_id: obj.id, modified: 'DOI created')
    end

    begin
      Sufia.queue.push(MintDoiJob.new(obj.id))
    rescue Exception => e
      Rails.logger.error "Unable to submit mint doi job: #{e.message}"
    end
  end
end
