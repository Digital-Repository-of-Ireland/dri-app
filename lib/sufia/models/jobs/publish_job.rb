require 'doi/doi'

class PublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing collection #{object.id}"

    query = Solr::Query.new("#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\" AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:reviewed")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |obj|
        o = ActiveFedora::Base.find(obj["id"], {:cast => true})
        o.status = "published" if o.status.eql?("reviewed")
        o.save

        DOI.mint_doi( o )
      end
    end

    unless object.status.eql?("published")
      object.status = "published"
      object.save

      DOI.mint_doi( object )
    end

  end

end
