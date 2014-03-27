class ReviewJob < ActiveFedoraPidBasedJob

  def queue_name
    :review
  end

  def run
    Rails.logger.info "Setting objects in #{object.id} to reviewed"

    done = false
    cursor_mark = "*"

    until done
      result = ActiveFedora::SolrService.query("collection_id_sim:\"#{object.id}\" AND status_ssim:draft", 
                 :raw => true, :rows => 100, :sort => 'id asc', :cursorMark => cursor_mark)

      unless result['response']['numFound'].to_i == 0
      
        collection_objects = result['response']['docs']
      
        collection_objects.each do |object|
          o = ActiveFedora::Base.find(object["id"], {:cast => true})
          o.status = "reviewed" if o.status.eql?("draft") 
          o.save
        end
      
      else
        done = true
      end
 
      cursor_mark = result['response']['nextCursorMark']
    end

  end

end
