require 'doi/doi'

class UnPublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "unpublishing #{object.id}"

    collection_objects = Batch.find(:ancestor_id_tesim => object.id)
    unless collection_objects.nil?
      collection_objects.each do |o|
        o.status = "draft" 
        o.save
      end
    end

  end

end
