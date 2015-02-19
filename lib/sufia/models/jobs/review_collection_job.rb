class ReviewCollectionJob < ActiveFedoraPidBasedJob

  def queue_name
    :review
  end

  def run
    Rails.logger.info "Setting subcollection objects in collection #{object.id} to reviewed"

    o = ActiveFedora::Base.find(object.id, {:cast => true})
    o.governed_items.each do | curr_object |
      curr_object.status = "reviewed" if curr_object.status.eql?("draft")
      curr_object.save
      # If object is a collection and has sub-collections, apply to governed_items
      if curr_object.is_collection?
        Sufia.queue.push(ReviewCollectionJob.new(curr_object.id)) unless curr_object.governed_items.nil?
      end
    end

  end

end
