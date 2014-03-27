require 'doi/doi'

class PublishJob < ActiveFedoraPidBasedJob

  def queue_name
    :publish
  end

  def run
    Rails.logger.info "Publishing reviewed objects in #{object.id}"

    done = false
    cursor_mark = "*"

    until done
      result = ActiveFedora::SolrService.query("collection_id_sim:\"#{object.id}\" AND status_ssim:reviewed",
                 :raw => true, :rows => 100, :sort => 'id asc', :cursorMark => cursor_mark)

      unless result['response']['numFound'].to_i == 0

        collection_objects = result['response']['docs']

        collection_objects.each do |object|
          o = ActiveFedora::Base.find(object["id"], {:cast => true})
          o.status = "published" if o.status.eql?("reviewed")
          o.save

          DOI.mint_doi( o )
        end

      else
        done = true
      end

      cursor_mark = result['response']['nextCursorMark']
    end

  end

end
