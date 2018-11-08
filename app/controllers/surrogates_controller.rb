class SurrogatesController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:index, :download]
  before_action :authenticate_user!, only: :index
  before_action :read_only, only: [:update]

  def index
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can? :read, params[:id]

    @surrogates = {}

    object_docs = solr_query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]))
    raise DRI::Exceptions::NotFound if object_docs.empty?

    all_surrogates(object_docs)

    respond_to do |format|
      format.json { @surrogates.to_json }
    end
  end

  def show
    raise DRI::Exceptions::BadRequest unless params[:object_id].present?
    raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can?(:read, params[:object_id])

    file = file_path(params[:object_id], params[:id], params[:surrogate])
    raise DRI::Exceptions::NotFound unless file

    if file =~ /\A#{URI.regexp(['http', 'https'])}\z/
      redirect_to file
      return
    end

    type, _ext = mime_type(file)

    # For derivatives stored on the local file system
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Content-Length'] = File.size(file).to_s
    send_file file, { type: type, disposition: 'inline' }
  end

  def download
    raise DRI::Exceptions::BadRequest unless params[:object_id].present?
    raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can?(:read, params[:object_id])

    @generic_file = retrieve_object! params[:id]
    if @generic_file
      @object_document = SolrDocument.find(params[:object_id])

      if @object_document.published?
        Gabba::Gabba.new(GA.tracker, request.host).event(@object_document.root_collection_id, "Download",  @object_document.id, 1, true)
      end

      file = file_path(params[:object_id], params[:id], surrogate_type_name)
      raise DRI::Exceptions::NotFound unless file

      type, ext = mime_type(file)
      name = "#{params[:id]}#{ext}"

      open(file) do |f|
        send_data(
          f.read,
          filename: name,
          type: type,
          disposition: 'attachment',
          stream: 'true',
          buffer_size: '4096'
        )
      end
      return
    end

    render text: 'Unable to find file', status: 404
  end

  def update
    raise DRI::Exceptions::BadRequest unless params[:id].present?
    enforce_permissions!('edit', params[:id])

    result_docs = ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]]))
    raise DRI::Exceptions::NotFound if result_docs.empty?

    result_docs.each do |r|
      doc = SolrDocument.new(r)

      if doc.collection?
        # Changed query to work with collections that have sub-collections (e.g. EAD)
        # - ancestor_id rather than collection_id field
        query = Solr::Query.new("#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:\"#{doc.id}\"")
        query.each { |object_doc| generate_surrogates(object_doc.id) }
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

          query.each do |object_doc|
            object_surrogates = surrogates(object_doc)
            @surrogates[object_doc.id] = object_surrogates unless object_surrogates.empty?
          end

        else
          object_surrogates = surrogates(doc)
          @surrogates[doc.id] = object_surrogates unless object_surrogates.empty?
        end
      end
    end

    def file_path(object_id, file_id, surrogate)
      base_name = File.basename(surrogate, ".*" )
      storage = StorageService.new
      storage.surrogate_url(
        object_id,
        "#{file_id}_#{base_name}"
      )
    end

    def generate_surrogates(object_id)
      enforce_permissions!('edit', object_id)
      query = Solr::Query.new("#{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object_id}\" AND NOT #{ActiveFedora.index_field_mapper.solr_name('preservation_only', :stored_searchable)}:true")
      query.each do |file_doc|
        begin
          # only characterize if necessary
          if file_doc[ActiveFedora.index_field_mapper.solr_name('characterization__mime_type')].present?
            # don't create surrogates of preservation only assets
            DRI.queue.push(CreateBucketJob.new(file_doc.id)) unless file_doc.preservation_only?
          else
            DRI.queue.push(CharacterizeJob.new(file_doc.id))
          end
          flash[:notice] = t('dri.flash.notice.generating_surrogates')
        rescue Exception => e
          flash[:alert] = t('dri.flash.alert.error_generating_surrogates', error: e.message)
        end
      end
    end

    def mime_type(file_uri)
      uri = URI.parse(file_uri)
      file_name = File.basename(uri.path)
      ext = File.extname(file_name)

      return MIME::Types.type_for(file_name).first.content_type, ext
    end

    def surrogates(object)
      surrogates = {}

      if can? :read, object
        storage = StorageService.new

        query = Solr::Query.new("#{ActiveFedora.index_field_mapper.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{object.id}\"")
        query.each do |file_doc|
          file_surrogates = storage.get_surrogates(object, file_doc)
          surrogates[file_doc.id] = file_surrogates unless file_surrogates.empty?
        end
      end

      surrogates
    end

    def surrogate_type_name
      if @generic_file.audio?
        'mp3'
      elsif @generic_file.video?
        'webm'
      elsif @generic_file.pdf?
        'pdf'
      elsif @generic_file.text?
        'pdf'
      elsif @generic_file.image?
        'full_size_web_format'
      end
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
