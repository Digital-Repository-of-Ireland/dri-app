class PublishJob < ActiveFedoraIdBasedJob
  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing collection #{object.id}"

    q_str = "#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\""
    q_str += " AND -#{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:draft"
    
    query = Solr::Query.new(q_str)

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object['id'], cast: true)

        if o.collection? && o.governed_items.present?
          Sufia.queue.push(PublishJob.new(o.id))
        else
          if o.status == 'reviewed'
            o.status = 'published'
            o.published_at = Time.now.utc.iso8601
            o.object_version = o.object_version.to_i + 1
            o.save

            # Do the preservation actions
            preservation = Preservation::Preservator.new(o)
            preservation.preserve(false, false, ['properties'])

            mint_doi(o)
          end
        end
      end
    end

    return if object.status == 'published'
    # publish the collection object
    object.status = 'published'
    object.published_at = Time.now.utc.iso8601
    object.object_version = object.object_version.to_i + 1
    object.save

    # Do the preservation actions
    preservation = Preservation::Preservator.new(object)
    preservation.preserve(false, false, ['properties'])

    mint_doi(object)
  end

  def mint_doi(obj)
    return if Settings.doi.enable != true || DoiConfig.nil?

    if obj.descMetadata.has_versions?
      DataciteDoi.create(object_id: obj.id, modified: 'DOI created', mod_version: obj.descMetadata.versions.last.uri)
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
