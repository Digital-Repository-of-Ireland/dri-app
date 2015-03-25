class SurrogatesController < ApplicationController

  def show
    unless params[:id].blank?
      enforce_permissions!("show",params[:id])

      @surrogates = {}

      result_docs = solr_query ( ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]) )

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        if doc[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].present? && doc[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first.eql?("collection")

          query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('collection_id', :facetable, type: :string)}:\"#{doc.id}\"")
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
      result_docs = solr_query ( ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]) )

      if result_docs.empty?
        raise Exceptions::NotFound
      end

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        if doc[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].present? && doc[ActiveFedora::SolrQueryBuilder.solr_name('file_type', :stored_searchable, type: :string)].first.eql?("collection")
          # Changed query to work with collections that have sub-collectionc (e.g. EAD) - ancestor_id rather than collection_id field
          query = Solr::Query.new("#{Solrizer.solr_name('ancestor_id', :facetable, type: :string)}:\"#{doc.id}\"")
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

  def download
    path = params[:path]
    content_type = MIME::Types.of(path)
    data = open(params[:path])
    send_data data.read, :filename => params[:name], :type => content_type, disposition: 'attachment', stream: 'true', buffer_size: '4096'
  end

  private

    def generate_surrogates(object_id)
      enforce_permissions!("edit", object_id)

      query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object_id}\"")

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

        query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object.id}\"")

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

      end

      surrogates
    end

    def solr_query( query )
      ActiveFedora::SolrService.query(query)
    end

end
