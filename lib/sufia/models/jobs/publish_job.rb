class PublishJob < ActiveFedoraIdBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing collection #{object.id}"

    query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\" AND #{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:reviewed")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})

        # If object is a collection and has sub-collections, apply to governed_items
        if o.is_collection?
          Sufia.queue.push(PublishJob.new(o.id)) if o.governed_items.present?
        else
          if o.status == "reviewed"
            o.status = "published"
            o.published_at = Time.now.utc.iso8601
            o.save

            mint_doi(o)
          end
        
        end
      end
    end

    # publish the collection object
    unless object.status == "published"
      object.status = "published"
      object.published_at = Time.now.utc.iso8601
      object.save

      mint_doi(object)
    end

  end

  def mint_doi(object)
    doi = if object.descMetadata.has_versions?
      DataciteDoi.create(object_id: object.id, modified: "DOI created", mod_version: object.descMetadata.versions.last.uri)
    else
      DataciteDoi.create(object_id: object.id, modified: "DOI created")
    end

    begin
      Sufia.queue.push(MintDoiJob.new(id))
    rescue Exception => e
      Rails.logger.error "Unable to submit mint doi job: #{e.message}"
    end
  end

end
