class SurrogatesController < ApplicationController

  def show
    unless params[:id].blank?
      enforce_permissions!("show",params[:id])

      @surrogates = {}

      result_docs = solr_query ( ActiveFedora::SolrService.construct_query_for_pids([params[:id]]) )

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        if doc['file_type_tesim'].present? && doc['file_type_tesim'].first.eql?("collection")

          query = Solr::Query.new("collection_id_sim:\"#{doc.id}\"")
          while query.has_more?
            objects = query.pop

            objects.each do |object|
              object_doc = SolrDocument.new(object)
              object_surrogates = surrogates(object_doc)
              @surrogates[object_doc.id] = object_surrogates unless object_surrogates.empty?
            end
          end

        else
          object_surrogates = surrogates(doc)
          @surrogates[doc.id] = object_surrogates unless object_surrogates.empty?
        end

      end
    else
      raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.html { render :text => @surrogates.to_json }
      format.json { @surrogates.to_json }
    end
  end

  def update
    unless params[:id].blank?
      enforce_permissions!("edit",params[:id])

      result_docs = solr_query ( ActiveFedora::SolrService.construct_query_for_pids([params[:id]]) )

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        if doc['file_type_tesim'].present? && doc['file_type_tesim'].first.eql?("collection")
       
          query = Solr::Query.new("collection_id_sim:\"#{doc.id}\"")
          while query.has_more?
            objects = query.pop
          
            objects.each do |object|
              object_doc = SolrDocument.new(object)
              generate_surrogates(object_doc.id)
            end
          end

        else
          generate_surrogates(doc.id)
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

    def generate_surrogates(object_id)
      enforce_permissions!("edit", object_id)

      query = Solr::Query.new("is_part_of_ssim:\"info:fedora/#{object_id}\"")
      
      while query.has_more?
      
        files = query.pop 
      
        unless files.empty?
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
    
    end

    def surrogates(object)
      surrogates = {}

      if can? :read, object
        storage = Storage::S3Interface.new

        query = Solr::Query.new("is_part_of_ssim:\"info:fedora/#{object.id}\"")
        
        while query.has_more?
          files = query.pop  

          unless files.empty?
            files.each do |mf|
              file_doc = SolrDocument.new(mf)
              file_surrogates = storage.get_surrogates(object, file_doc)
              surrogates[file_doc.id] = file_surrogates unless file_surrogates.empty?
            end
          end
        end

        storage.close
      end
      
      surrogates
    end

    def solr_query( query )
      ActiveFedora::SolrService.query(query)
    end

end
