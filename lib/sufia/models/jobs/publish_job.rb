require 'doi/doi'

class PublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

=begin
  def run
    Rails.logger.info "Publishing collection #{object.id}"

    # Querying by root_collection_id gets all objects, subcollections belonging to the collectionid passed as parameter
    # Publishing all object/subcollections with a reviewed status
    query = Solr::Query.new("#{Solrizer.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{object.id}\" AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:reviewed")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |obj|
        o = ActiveFedora::Base.find(obj["id"], {:cast => true})
        if o.status.eql?("reviewed")
          o.status = "published"
          o.published_at = Time.now.utc.iso8601
          o.save
        end

        DOI.mint_doi( o )
      end
    end

    unless object.status.eql?("published")
      object.status = "published"
      object.published_at = Time.now.utc.iso8601
      object.save

      DOI.mint_doi( object )
    end

  end
=end

  def run
    Rails.logger.info "Publishing collection #{object.id}"

    query = Solr::Query.new("#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\" AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:reviewed")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})
        if o.status.eql?("reviewed")
          o.status = "published"
          o.published_at = Time.now.utc.iso8601
          o.save
        end

        # If object is a collection and has sub-collections, apply to governed_items
        if o.is_collection?
          Sufia.queue.push(PublishJob.new(o.id)) unless (o.governed_items.nil? || o.governed_items.empty?)
        else
          DOI.mint_doi( o )
        end

      end
    end

    unless object.status.eql?("published")
      object.status = "published"
      object.published_at = Time.now.utc.iso8601
      object.save

      DOI.mint_doi( object )
    end

  end

end
