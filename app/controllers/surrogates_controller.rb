class SurrogatesController < ApplicationController

  def update
    unless params[:id].blank?
      enforce_permissions!("edit",params[:id])

      solr_query = ActiveFedora::SolrService.construct_query_for_pids([params[:id]])
      result_docs = ActiveFedora::SolrService.query(solr_query)

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        if doc['file_type_tesim'].present? && doc['file_type_tesim'].first.eql?("collection")
       
          objects_query = "collection_id_sim:\"#{doc.id}\""
          objects = ActiveFedora::SolrService.query(objects_query)

          objects.each do |object|
            object_doc = SolrDocument.new(object)
            surrogates_for_object(object_doc.id)
          end

        else

          surrogates_for_object(doc.id)

        end
      end
    else
      raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { }
    end
  end

  private

    def surrogates_for_object(object_id)
      enforce_permissions!("edit", object_id)

      files_query = "is_part_of_ssim:\"info:fedora/#{object_id}\""
      files = ActiveFedora::SolrService.query(files_query)

      files.each do |mf|
        file_doc = SolrDocument.new(mf)
        begin
          Sufia.queue.push(CharacterizeJob.new(file_doc.id))
          flash[:notice] = t('dri.flash.notice.generating_surrogates')
        rescue Exception => e
          flash[:alert] = t('dri.flash.alert.error_generating_surrogates', :error => e.message)
        end
      end
    end

end
