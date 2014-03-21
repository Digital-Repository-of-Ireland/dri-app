require 'doi/doi'

class PublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing #{object.id}"

    collection_objects = ActiveFedora::SolrService.query("collection_id_sim:\"#{object.id}\"")
    unless collection_objects.nil?
      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})
        o.status = "published" if o.status.eql?("reviewed") 
        o.save

        DOI.mint_doi( o )
      end
    end

  end

end
