require 'doi/doi'

class PublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing reviewed objects in #{object.id}"

    query = Solr::Query.new("collection_id_sim:\"#{object.id}\" AND status_ssim:reviewed")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})
        o.status = "published" if o.status.eql?("reviewed")
        o.save

        DOI.mint_doi( o )
      end
    end

  end

end
