# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:list_assets, :download]
  before_action :authenticate_user!, only: :list_assets
  before_action :add_cors_to_json, only: :list_assets
  before_action :read_only, except: [:show, :download, :list_assets]
  before_action ->(id=params[:object_id]) { locked(id) }, except: [:show, :download, :list_assets, :retrieve]

  require 'validators'

  include DRI::Citable

  def show
    if params[:surrogate].present?
      show_surrogate
      return
    else
      result = ActiveFedora::SolrService.query("id:#{params[:object_id]}")
      @document = SolrDocument.new(result.first)

      @generic_file = retrieve_object! params[:id]
      status(@generic_file.id)
      can_view?

      respond_to do |format|
        format.html
        format.json { render json: @generic_file }
      end
    end
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the master file
  def download
    type = params[:type].presence || 'masterfile'

    case type
    when 'surrogate'
      @generic_file = retrieve_object! params[:id]
      if @generic_file
        object = @generic_file.batch
        if object.published?
          Gabba::Gabba.new(GA.tracker, request.host).event(object.root_collection.first, "Download",  object.id, 1, true)
        end
        download_surrogate(surrogate_type_name)
        return
      end

    when 'masterfile'
      enforce_permissions!('edit', params[:object_id]) if params[:version].present?

      result = ActiveFedora::SolrService.query("id:#{params[:object_id]}")
      @document = SolrDocument.new(result.first)

      @generic_file = retrieve_object! params[:id]
      if @generic_file
        can_view?

        object = @generic_file.batch
        if object.published?
          Gabba::Gabba.new(GA.tracker, request.host).event(object.root_collection.first, "Download", object.id, 1, true)
        end
        lfile = local_file
        if lfile
          response.headers['Content-Length'] = File.size?(lfile.path).to_s
          send_file lfile.path,
                type: lfile.mime_type || @generic_file.mime_type,
                stream: true,
                buffer: 4096,
                disposition: "attachment; filename=\"#{File.basename(lfile.path)}\";",
                url_based_filename: true
          return
        end
      end
    end

    render text: 'Unable to find file', status: 500
  end

  def destroy
    enforce_permissions!('edit', params[:object_id])

    @object = retrieve_object!(params[:object_id])
    @generic_file = retrieve_object!(params[:id])

    raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '') if @object.status == 'published'

    @object.object_version ||= '1'
    @object.increment_version
    @object.save

    @generic_file.delete
    delete_surrogates(params[:object_id], @generic_file.id)

    # Do the preservation actions
    addfiles = []
    delfiles = ["#{@generic_file.id}_#{@generic_file.label}"]
    preservation = Preservation::Preservator.new(@object)
    preservation.preserve_assets(addfiles, delfiles)

    flash[:notice] = t('dri.flash.notice.asset_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: params[:object_id] }
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    datastream = 'content'
    file_upload = upload_from_params

    @object = retrieve_object!(params[:object_id])
    @generic_file = retrieve_object! params[:id]

    preserve_file(file_upload, datastream, params)
    filename = params[:file_name].presence || file_upload.original_filename

    url = "#{URI.escape(download_url)}?version=#{@file.version}"

    file_content = GenericFileContent.new(user: current_user, generic_file: @generic_file)
    if file_content.external_content(url, filename)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      mint_doi(@object, 'asset modified') if @object.status == 'published'
    else
      message = @generic_file.errors.full_messages.join(', ')
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
      logger.error "Error saving file: #{message}"
    end

    respond_to do |format|
      format.html { redirect_to object_file_url(params[:object_id], @generic_file.id) }
      format.json do
        response = { checksum: @file.checksum }
        response[:warning] = @warnings if @warnings

        render json: response, status: :ok
      end
    end
  end

  # Stores an uploaded file to the local filesystem and then attaches it to one
  # of the objects datastreams. content is used by default.
  #
  def create
    enforce_permissions!('edit', params[:object_id])

    datastream = 'content'
    file_upload = upload_from_params

    @object = retrieve_object!(params[:object_id])
    if @object.nil?
      flash[:notice] = t('dri.flash.notice.specify_object_id')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    preservation = params[:preservation].presence == 'true' ? true : false
    build_generic_file(object: @object, user: current_user, preservation: preservation)
    preserve_file(file_upload, datastream, params)
    filename = params[:file_name].presence || file_upload.original_filename

    url = "#{URI.escape(download_url)}?version=#{@file.version}"

    file_content = GenericFileContent.new(user: current_user, generic_file: @generic_file)
    if file_content.external_content(url, filename)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      mint_doi(@object, 'asset added') if @object.status == 'published'
    else
      message = @generic_file.errors.full_messages.join(', ')
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
      @warnings = t('dri.flash.alert.error_saving_file', error: message)
      logger.error "Error saving file: #{message}"
    end

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: params[:object_id] }
      format.json do
        response = { checksum: @file.checksum }
        response[:warnings] = @warnings if @warnings

        render json: response, status: :created
      end
    end
  end

  # API call: takes one or more object ids and returns a list of asset urls
  def list_assets
    @list = []

    raise DRI::Exceptions::BadRequest unless params[:objects].present?

    solr_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(
      params[:objects].map { |o| o.values.first }
    )
    result_docs = Solr::Query.new(solr_query)
    result_docs.each do |doc|
      item = list_files_with_surrogates(doc)
      @list << item unless item.empty?
    end

    raise DRI::Exceptions::NotFound if @list.empty?

    respond_to do |format|
      format.json
    end
  end

  private

    def add_cors_to_json
      if request.format == "application/json"
        response.headers["Access-Control-Allow-Origin"] = "*"
      end
    end

    def build_generic_file(object:, user:, preservation: false)
      @generic_file = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
      @generic_file.batch = object
      @generic_file.apply_depositor_metadata(user)
      @generic_file.preservation_only = 'true' if preservation
    end

    def mime_type(file_uri)
      uri = URI.parse(file_uri)
      file_name = File.basename(uri.path)
      ext = File.extname(file_name)

      return MIME::Types.type_for(file_name).first.content_type, ext
    end

    def can_view?
      if (!(can?(:read, params[:object_id]) && @document.read_master? && @document.published?) && !can?(:edit, @document))
        raise Hydra::AccessDenied.new(
          t('dri.views.exceptions.view_permission'),
          :read_master,
          params[:object_id]
        )
      end
    end

    def delete_surrogates(bucket_name, file_prefix)
      storage = StorageService.new
      storage.delete_surrogates(bucket_name, file_prefix)
    end

    def download_surrogate(surrogate_name)
      raise DRI::Exceptions::BadRequest unless params[:object_id].present?
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied')) unless can?(:read, params[:object_id])

      file = file_path(params[:object_id], params[:id], surrogate_name)
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
    end

    def preserve_file(filedata, datastream, params)
      checksum = params[:checksum]
      filename = params[:file_name].presence || filedata.original_filename
      filename = "#{@generic_file.id}_#{filename}"

      # Update object version
      @object.object_version ||= '1'
      @object.increment_version

      begin
        @object.save!
      rescue ActiveRecord::ActiveRecordError => e
        logger.error "Could not update object version number for #{@object.id} to version #{object_version}"
        raise Exceptions::InternalError
      end

      @file = LocalFile.build_local_file(
        object: @object,
        generic_file: @generic_file,
        data:filedata,
        datastream: datastream,
        opts: { filename: filename, mime_type: @mime_type }
      )

      # Do the preservation actions
      addfiles = [filename]
      delfiles = []
      delfiles = ["#{@generic_file.id}_#{@generic_file.label}"] if params[:action] == 'update'

      preservation = Preservation::Preservator.new(@object)
      preservation.preserve_assets(addfiles, delfiles)
    end

    def show_surrogate
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

    def download_url
      url_for(
        controller: 'assets',
        action: 'download',
        object_id: @object.id,
        id: @generic_file.id,
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
      )
    end

    def file_path(object_id, file_id, surrogate)
      base_name = File.basename(surrogate, ".*" )
      storage = StorageService.new
      storage.surrogate_url(
        object_id,
        "#{file_id}_#{base_name}"
      )
    end

    def list_files_with_surrogates(doc)
      item = {}
      item['pid'] = doc.id
      item['files'] = []

      files = doc.assets

      files.each do |file_doc|
        file_list = {}

        if (doc.read_master? && can?(:read, doc)) || can?(:edit, doc)
          url = url_for(file_download_url(doc.id, file_doc.id))
          file_list['masterfile'] = url
        end

        if can?(:read, doc)
          surrogates = doc.surrogates(file_doc.id)
          surrogates.each { |file, loc| file_list[file] = loc }
        end

        item['files'].push(file_list)
      end

      item
    end

    def local_file(datastream = 'content')
      search_params = { f: @generic_file.id, d: datastream }
      search_params[:v] = params[:version] if params[:version].present?

      query = 'fedora_id LIKE :f AND ds_id LIKE :d'
      query << ' AND version = :v' if search_params[:v].present?

      LocalFile.where(query, search_params).order(version: :desc).first
    rescue ActiveRecord::RecordNotFound
      raise DRI::Exceptions::InternalError, "Unable to find requested file"
    rescue ActiveRecord::ActiveRecordError
      raise DRI::Exceptions::InternalError, "Error finding file"
    end

    def local_file_ingest(name)
      upload_dir = Rails.root.join(Settings.dri.uploads)
      File.new(File.join(upload_dir, name))
    end

    def status(file_id)
      ingest_status = IngestStatus.where(asset_id: file_id)

      @status = {}
      if ingest_status.present?
        status = ingest_status.first
        @status[:status] = status.status

        @status[:jobs] = {}
        status.job_status.each do |job|
          @status[:jobs][job.job] = { status: job.status, message: job.message }
        end
      end
    end

    def upload_from_params
      if params[:Filedata].blank? && params[:Presfiledata].blank? && params[:local_file].blank?
        flash[:notice] = t('dri.flash.notice.specify_file')
        redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
        return
      end

      file_upload = if params[:local_file].present?
                      local_file_ingest(params[:local_file])
                    else
                      params[:Filedata].presence || params[:Presfiledata].presence
                    end

      validate_upload(file_upload)

      file_upload
    end

    def validate_upload(file_upload)
      @mime_type = Validators.file_type(file_upload)
      Validators.validate_file(file_upload, @mime_type)
    rescue DRI::Exceptions::UnknownMimeType, DRI::Exceptions::WrongExtension, DRI::Exceptions::InappropriateFileType
      message = t('dri.flash.alert.invalid_file_type')
      flash[:alert] = message
      @warnings = message
    rescue DRI::Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_file', name: file_upload.original_filename)
    end
end
