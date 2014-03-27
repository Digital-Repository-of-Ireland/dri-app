class ReviewJob < ActiveFedoraPidBasedJob

  def queue_name
    :review
  end

  def run
    Rails.logger.info "Setting objects in #{object.id} to reviewed"
    
    query = Solr::Query.new("collection_id_sim:\"#{object.id}\" AND status_ssim:draft")

    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = ActiveFedora::Base.find(object["id"], {:cast => true})
        o.status = "reviewed" if o.status.eql?("draft") 
        o.save
      end
    end
  
  end

end
