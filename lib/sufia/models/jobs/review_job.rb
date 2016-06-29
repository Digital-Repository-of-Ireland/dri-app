class ReviewJob < ActiveFedoraIdBasedJob

  def queue_name
    :review
  end

  def run
    Rails.logger.info "Setting objects in #{object.id} to reviewed"

    query = Solr::Query.new("#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\" AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:draft")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {cast: true})
        if o.status == "draft"
          o.status = "reviewed"
          o.object_version = o.object_version.to_i + 1
          o.save

          # Do the preservation actions
          preservation = Preservation::Preservator.new(o)
          preservation.preserve(false, false, ['properties'])
        end
      end
    end

  end

end
