class SurrogatesController < ApplicationController
  before_action :read_only, except: [:show]

  def show
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can? :read, params[:id]

    @surrogates = {}

    object_docs = solr_query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]))
    raise DRI::Exceptions::NotFound if object_docs.empty?

    all_surrogates object_docs

    respond_to do |format|
      format.json { @surrogates.to_json }
    end
  end

  def update
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('edit', params[:id])

    result_docs = solr_query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]))
    raise DRI::Exceptions::NotFound if result_docs.empty?

    result_docs.each do |r|
      doc = SolrDocument.new(r)
      
      if doc.collection?
        # Changed query to work with collections that have sub-collections (e.g. EAD) 
        # - ancestor_id rather than collection_id field
        query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"#{doc.id}\"")
        query.each_solr_document { |object_doc| generate_surrogates(object_doc.id) }
      else
        generate_surrogates(doc.id)
      end
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.json {}
    end
  end

  private

    def all_surrogates(result_docs)
      result_docs.each do |r|
        doc = SolrDocument.new(r)

        if doc.collection?
          query = Solr::Query.new("#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{doc.id}\"")

          query.each_solr_document do |object_doc|
            object_surrogates = surrogates(object_doc)
            @surrogates[object_doc.id] = object_surrogates unless object_surrogates.empty?
          end

        else
          object_surrogates = surrogates(doc)
          @surrogates[doc.id] = object_surrogates unless object_surrogates.empty?
        end
      end
    end

    def generate_surrogates(object_id)
      enforce_permissions!('edit', object_id)
      query = Solr::Query.new("#{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object_id}\" AND NOT #{ActiveFedora.index_field_mapper.solr_name('preservation_only', :stored_searchable)}:true")
      query.each_solr_document do |file_doc|
        begin
          # only characterize if necessary
          if file_doc[ActiveFedora.index_field_mapper.solr_name('characterization__mime_type')].present?
            DRI.queue.push(CreateBucketJob.new(file_doc.id))
          else
            puts "Characterize #{file_doc.id}"
            DRI.queue.push(CharacterizeJob.new(file_doc.id))
          end
          flash[:notice] = t('dri.flash.notice.generating_surrogates')
        rescue Exception => e
          flash[:alert] = t('dri.flash.alert.error_generating_surrogates', error: e.message)
        end
      end
    end

    def surrogates(object)
      surrogates = {}

      if can? :read, object
        storage = StorageService.new

        query = Solr::Query.new("#{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object.id}\"")
        query.each_solr_document do |file_doc|
          file_surrogates = storage.get_surrogates(object, file_doc)
          surrogates[file_doc.id] = file_surrogates unless file_surrogates.empty?
        end
      end

      surrogates
    end

    def solr_query(query)
      ActiveFedora::SolrService.query(query)
    end

    def validate_uri(surrogate_url)
      uri = URI(surrogate_url)

      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_url') unless %w(http https).include? uri.scheme
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_url') unless uri.host == URI.parse(Settings.S3.server).host

      uri
    rescue URI::InvalidURIError
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_url')
    end
end
