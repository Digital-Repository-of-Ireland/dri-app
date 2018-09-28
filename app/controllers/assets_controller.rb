# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:list_assets, :download]
  before_action :authenticate_user!, only: :list_assets
  before_action :add_cors_to_json, only: :list_assets
  before_action :read_only, except: [:show, :download, :list_assets]
  before_action ->(id=params[:object_id]) { locked(id) }, except: [:show, :download, :list_assets]

  require 'validators'

  include DRI::Citable

  def show
    @object_document = SolrDocument.find(params[:object_id])
    @generic_file = retrieve_object! params[:id]

    status(@generic_file.id)
    can_view?

    respond_to do |format|
      format.html
      format.json { render json: @generic_file }
    end
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the master file
  def download
    enforce_permissions!('edit', params[:object_id]) if params[:version].present?

    @generic_file = retrieve_object! params[:id]
    if @generic_file
      @object_document = SolrDocument.find(params[:object_id])

      can_view?

      if @object_document.published?
        Gabba::Gabba.new(GA.tracker, request.host).event(@object_document.root_collection_id, "Download", @object_document.id, 1, true)
      end

      local_file = GenericFileContent.new(generic_file: @generic_file).local_file(params[:version])

      if local_file
        response.headers['Content-Length'] = File.size?(local_file.path).to_s
        send_file local_file.path,
              type: local_file.mime_type || @generic_file.mime_type,
              stream: true,
              buffer: 4096,
              disposition: "attachment; filename=\"#{File.basename(local_file.path)}\";",
              url_based_filename: true
        return
      end
    end

    render text: 'Unable to find file', status: 404
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

    file_upload, mime_type = upload_from_params

    @object = retrieve_object! params[:object_id]
    @generic_file = retrieve_object! params[:id]

    filename = params[:file_name].presence || file_upload.original_filename
    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)

    if file_content.update_content(file_upload, filename, mime_type, download_url)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      mint_doi(@object, 'asset modified') if @object.status == 'published'
    else
      message = @generic_file.errors.full_messages.join(', ')
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
      logger.error "Error saving file: #{message}"
    end

    respond_to do |format|
      format.html { redirect_to object_file_url(@object.id, @generic_file.id) }
      format.json do
        response = { checksum: preserved_file.checksum }
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

    file_upload, mime_type = upload_from_params

    @object = retrieve_object! params[:object_id]
    if @object.nil?
      flash[:notice] = t('dri.flash.notice.specify_object_id')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    preservation = params[:preservation].presence == 'true' ? true : false
    @generic_file = build_generic_file(object: @object, user: current_user, preservation: preservation)

    filename = params[:file_name].presence || file_upload.original_filename
    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)

    if file_content.add_content(file_upload, filename, mime_type, download_url)
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
        response = { checksum: file_content.checksum }
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
      generic_file = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
      generic_file.batch = object
      generic_file.apply_depositor_metadata(user)
      generic_file.preservation_only = 'true' if preservation

      generic_file
    end

    def can_view?
      if (!(can?(:read, params[:object_id]) && @object_document.read_master? && @object_document.published?) && !can?(:edit, @object_document))
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

    def download_url
      url_for(
        controller: 'assets',
        action: 'download',
        object_id: @object.id,
        id: @generic_file.id,
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
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

      mime_type = validate_upload(file_upload)

      return file_upload, mime_type
    end

    def validate_upload(file_upload)
      mime_type = Validators.file_type(file_upload)
      Validators.validate_file(file_upload, mime_type)

      mime_type
    rescue DRI::Exceptions::UnknownMimeType, DRI::Exceptions::WrongExtension, DRI::Exceptions::InappropriateFileType
      message = t('dri.flash.alert.invalid_file_type')
      flash[:alert] = message
      @warnings = message
      mime_type
    rescue DRI::Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.invalid_file', name: file_upload.original_filename)
    end
end
