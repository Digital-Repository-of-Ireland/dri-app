# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:index, :download]
  before_action :authenticate_user!, only: [:index]
  before_action :read_only, except: [:index, :show, :download]
  before_action ->(id=params[:object_id]) { locked(id) }, except: [:index, :show, :download]

  require 'validators'

  include DRI::Citable
  include DRI::Versionable

  def index
    enforce_permissions!('edit', params[:object_id])

    @document = SolrDocument.find(params[:object_id])
    @assets = @document.assets(with_preservation: true, ordered: true)

    @status = status_info(@assets)
  end

  def show
    @document = SolrDocument.find(params[:object_id])
    can_view?

    @presenter = DRI::ObjectInMyCollectionsPresenter.new(@document, view_context)
    @generic_file = retrieve_object! params[:id]

    @status = status(@generic_file.id)

    respond_to do |format|
      format.html
      format.json { render json: @generic_file }
    end
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  def download
    enforce_permissions!('edit', params[:object_id]) if params[:version].present?

    @generic_file = retrieve_object! params[:id]
    if @generic_file
      @document = SolrDocument.find(params[:object_id])

      can_view?

      if @document.published?
        Gabba::Gabba.new(GA.tracker, request.host).event(
          @document.root_collection_id,
          'Download',
          @document.id,
          1,
          true
        )
      end

      local_file = GenericFileContent.new(generic_file: @generic_file).local_file(params[:version])

      if local_file
        response.headers['Content-Length'] = File.size?(local_file.path).to_s
        send_file local_file.path,
              type: local_file.mime_type || @generic_file.mime_type,
              stream: true,
              buffer: 4096,
              disposition: "attachment; filename=\"#{@generic_file.filename.first}\";",
              url_based_filename: true
        return
      end
    end

    render plain: 'Unable to find file', status: 404
  end

  def destroy
    enforce_permissions!('edit', params[:object_id])

    object = retrieve_object!(params[:object_id])
    generic_file = retrieve_object!(params[:id])

    if object.status == 'published' && !current_user.is_admin?
      raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    object.object_version ||= '1'
    object.increment_version
    object.save
    record_version_committer(object, current_user)

    delfiles = ["#{generic_file.id}_#{generic_file.label}"]
    delete_surrogates(params[:object_id], generic_file.id)
    generic_file.delete

    # Do the preservation actions
    preservation = Preservation::Preservator.new(object)
    preservation.preserve_assets({ deleted: { 'content' => delfiles }})

    flash[:notice] = t('dri.flash.notice.asset_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'my_collections', action: 'show', id: params[:object_id] }
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    file_upload = upload_from_params

    @object = retrieve_object! params[:object_id]
    @generic_file = retrieve_object! params[:id]

    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)
    begin
      if file_content.update_content(file_upload, download_url)
        flash[:notice] = t('dri.flash.notice.file_uploaded')
        record_version_committer(@object, current_user)

        mint_doi(@object, 'asset modified') if @object.status == 'published'
      else
        message = @generic_file.errors.full_messages.join(', ')
        flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
        logger.error "Error saving file: #{message}"
      end
    rescue DRI::Exceptions::MoabError => e
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: e.message)
      logger.error "Error saving file: #{e.message}"
    end

    respond_to do |format|
      format.html { redirect_to object_file_url(@object.id, @generic_file.id) }
      format.json do
        response = { checksum: file_content.checksum }
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

    file_upload = upload_from_params

    @object = retrieve_object! params[:object_id]
    if @object.nil?
      flash[:notice] = t('dri.flash.notice.specify_object_id')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    preservation = params[:preservation].presence == 'true' ? true : false
    @generic_file = build_generic_file(object: @object, user: current_user, preservation: preservation)

    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)

    if file_content.add_content(file_upload, download_url)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      record_version_committer(@object, current_user)
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

  private

    def build_generic_file(object:, user:, preservation: false)
      generic_file = DRI::GenericFile.new(id: DRI::Noid::Service.new.mint)
      generic_file.batch = object
      generic_file.apply_depositor_metadata(user)
      generic_file.preservation_only = 'true' if preservation

      generic_file
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

    def download_url
      url_for(
        controller: 'assets',
        action: 'download',
        object_id: @object.id,
        id: @generic_file.id
      )
    end

    def local_file_ingest(name)
      upload_dir = Rails.root.join(Settings.dri.uploads)
      File.new(File.join(upload_dir, name))
    end

    def status_info(files)
      statuses = {}

      files.each do |file|
        statuses[file.id] = file_status(file.id)
      end

      statuses
    end

    def file_status(file_id)
      ingest_status = status(file_id)
      if ingest_status.present?
        { status: ingest_status[:status] }
      else
        { status: 'unknown' }
      end
    end

    def status(file_id)
      ingest_status = IngestStatus.find_by(asset_id: file_id)

      status_info = {}
      if ingest_status
        status_info[:status] = ingest_status.completed_status

        status_info[:jobs] = {}
        ingest_status.job_status.each do |job|
          status_info[:jobs][job.job] = { status: job.status, message: job.message }
        end
      end

      status_info
    end

    def surrogates_with_url(file_id, surrogates)
      surrogates.each do |key, _path|
        surrogates[key] = url_for(object_file_url(
                            object_id: @document.id, id: file_id, surrogate: key
                          ))
      end
    end

    def upload_from_params
      if params[:Filedata].blank? && params[:Presfiledata].blank? && params[:local_file].blank?
        flash[:notice] = t('dri.flash.notice.specify_file')
        redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
        return
      end

      upload = if params[:local_file].present?
                 local_file_ingest(params[:local_file])
               else
                 params[:Filedata].presence || params[:Presfiledata].presence
               end

      mime_type = validate_upload(upload)

      file_upload = { file_upload: upload,
                      mime_type: mime_type,
                      filename: params[:file_name].presence || upload.original_filename
                    }

      return file_upload
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
