class ReviewCollectionJob < ActiveFedoraIdBasedJob

  def queue_name
    :review
  end

  def run
    Rails.logger.info "Setting sub-collection objects in collection #{object.id} to reviewed"

    query = Solr::Query.new("#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\" AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:draft")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {cast: true})
        if o.status == 'draft'
          o.status = 'reviewed'
          o.save
        end

        # If object is a collection and has sub-collections, apply to governed_items
        if o.collection?
          Sufia.queue.push(ReviewCollectionJob.new(o.id)) unless o.governed_items.blank?
        end
      end
    end

  end

end
