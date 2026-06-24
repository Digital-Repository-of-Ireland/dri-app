# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController
  before_action :authenticate_user_from_token!, only: [:index, :download]
  before_action :authenticate_user!, only: [:index]
  before_action :read_only, except: [:index, :show, :download]
  before_action ->(id=params[:object_id]) { locked(id) }, except: [:index, :show, :download]

  require 'validators'

  include DRI::Versionable
  include DRI::Asset::MimeTypes

  def new
    enforce_permissions!('edit', params[:object_id])
    @document = SolrDocument.find(params[:object_id])
  end

  def index
    enforce_permissions!('edit', params[:object_id])
    @document = SolrDocument.find(params[:object_id])
    @assets   = @document.assets(with_preservation: true, ordered: true)
    @status   = @document.assets_status_info(@assets)
  end

  def show
    @document     = SolrDocument.find(params[:object_id])
    enforce_viewable!
    @presenter    = DRI::ObjectInMyCollectionsPresenter.new(@document, view_context)
    @generic_file = retrieve_object!(params[:id])
    @status       = @document.ingest_status_info(@generic_file.alternate_id)

    respond_to do |format|
      format.html
      format.json { render json: @generic_file }
    end
  end

  def download
    @generic_file = retrieve_object!(params[:id])
    raise DRI::Exceptions::NotFound unless @generic_file && File.file?(@generic_file.path)

    @document = SolrDocument.find(params[:object_id])
    enforce_viewable!

    response.header['Accept-Ranges'] = 'bytes'

    if request.headers['range']
      send_file_with_range @generic_file.path,
        type:        @generic_file.mime_type || 'application/octet-stream',
        disposition: 'inline'
    else
      response.headers['Content-Length'] = File.size?(@generic_file.path).to_s
      send_file @generic_file.path,
        type:        @generic_file.mime_type || 'application/octet-stream',
        stream:      true,
        buffer:      4096,
        disposition: "attachment; filename=\"#{@generic_file.filename.first}\";"
    end
  end

  def destroy
    enforce_permissions!('edit', params[:object_id])

    object = retrieve_object!(params[:object_id])
    raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '') \
      if object.status == 'published' && !current_user.is_admin?

    generic_file = retrieve_object(params[:id])

    # Guard: Solr index is stale — object exists in index but not in the database
    if generic_file.nil?
      SolrDocument.delete(params[:id])
      flash[:notice] = t('dri.flash.notice.asset_deleted')
      return respond_to { |format| format.html { redirect_to object_files_path(object) } }
    end

    begin
      DRI::GenericFile.transaction do
        delete_surrogates(params[:object_id], generic_file.alternate_id)
        generic_file.destroy!
      end

      object.increment_version
      object.save!
      record_version_committer(object, current_user, 'asset delete')

      if object.status == 'published'
        DoiSyncService.new(object, reason: 'asset modified').call
      end

      delfiles     = ["#{generic_file.alternate_id}_#{generic_file.label}"]
      preservation = Preservation::Preservator.new(object)
      preservation.preserve_assets(deleted: { 'content' => delfiles })

      flash[:notice] = t('dri.flash.notice.asset_deleted')
    rescue RuntimeError => e
      logger.error "Could not delete file #{generic_file.alternate_id}: #{e.message}"
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: e.message)
    end

    respond_to { |format| format.html { redirect_to object_files_path(object) } }
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    file_upload   = build_upload_from_params or return
    @object       = retrieve_object!(params[:object_id])
    @generic_file = @object.generic_files
                           .joins(:alternate_identifier)
                           .find_by(dri_identifiers: { alternate_id: params[:id] })

    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)

    begin
      @object.increment_version

      if file_content.update_content(file_upload)
        record_version_committer(@object, current_user, 'asset update')
        file_content.characterize if file_content.has_content?
        flash[:notice] = t('dri.flash.notice.file_uploaded')
      else
        message = @generic_file.errors.full_messages.join(', ')
        flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
        logger.error "Error saving file: #{message}"
      end
    rescue DRI::Exceptions::MoabError => e
      flash[:alert] = @warnings = t('dri.flash.alert.error_saving_file', error: e.message)
      logger.error "Error saving file: #{e.message}"
    end

    respond_to do |format|
      format.html { redirect_to object_file_url(@object.alternate_id, @generic_file.alternate_id) }
      format.json do
        response = { checksum: file_content.checksum }
        response[:warning] = @warnings if @warnings
        render json: response, status: :ok
      end
    end
  end

  def create
    enforce_permissions!('edit', params[:object_id])

    file_upload = build_upload_from_params or return
    @object     = retrieve_object!(params[:object_id])

    if @object.nil?
      flash[:notice] = t('dri.flash.notice.specify_object_id')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    preservation  = params[:preservation].presence == '1'
    @generic_file = build_generic_file(object: @object, user: current_user, preservation: preservation)
    file_content  = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)

    begin
      @object.increment_version

      if file_content.add_content(file_upload)
        record_version_committer(@object, current_user, 'asset added')
        file_content.characterize if file_content.has_content?
        @message = t('dri.flash.notice.file_uploaded')
        @status  = :created
      else
        error_message = @generic_file.errors.full_messages.join(', ')
        @warnings = t('dri.flash.alert.error_saving_file', error: error_message)
        @status   = :internal_server_error
        logger.error "Error saving file: #{error_message}"
      end
    rescue DRI::Exceptions::MoabError => e
      @warnings = t('dri.flash.alert.error_saving_file', error: e.message)
      @status   = :internal_server_error
      logger.error "Error saving file: #{e.message}"
    end

    respond_to do |format|
      format.html do
        flash[:notice] = @message   if @message
        flash[:alert]  = @warnings  if @warnings
        redirect_to controller: 'my_collections', action: 'show', id: params[:object_id]
      end
      format.json do
        response = {}
        response[:warnings] = @warnings if @warnings
        response[:messages] = @message  if @message && @status == :created
        render json: response, status: @status
      end
    end
  end

  def upload
    enforce_permissions!('edit', params[:object_id])

    data                 = JSON.parse(request.body.string)
    storage              = Storage::S3Interface.new
    storage_bucket_name  = "users.#{::Mail::Address.new(current_user.email).local}.uploads"

    if storage.create_upload_bucket(storage_bucket_name)
      url      = storage.put_url(storage_bucket_name, data['filename'], data['contentType'], true)
      response = { method: 'PUT', url: url, headers: { 'content-type' => data['contentType'] } }
      render json: response, status: :ok
    else
      render json: { message: t('dri.flash.alert.error_saving_file', error: 'S3 upload failed') }, status: :internal_server_error
    end
  end

  private

    def build_generic_file(object:, user:, preservation: false)
      DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint).tap do |gf|
        gf.digital_object     = object
        gf.apply_depositor_metadata(user)
        gf.preservation_only  = 'true' if preservation
      end
    end

    # Raises AccessDenied unless the current user can view the document's master file.
    def enforce_viewable!
      return if viewable? || editor?

      raise Blacklight::AccessControls::AccessDenied.new(
        t('dri.views.exceptions.view_permission'),
        :read_master,
        params[:object_id]
      )
    end

    def viewable?
      can?(:read, params[:object_id]) && (@document.read_master? || master_as_surrogate?) && @document.published?
    end

    def master_as_surrogate?
      @generic_file && (@generic_file.threeD? || @generic_file.interactive_resource?)
    end

    def editor?
      can?(:edit, @document)
    end

    def delete_surrogates(bucket_name, file_prefix)
      StorageService.new.delete_surrogates(bucket_name, file_prefix)
    end

    # Builds the upload hash from whichever param source is present.
    # Returns nil and handles the redirect itself if no file was supplied,
    # allowing callers to use the `or return` pattern.
    def build_upload_from_params
      if params[:file].blank? && params[:local_file].blank? && params[:s3_url].blank?
        flash[:notice] = t('dri.flash.notice.specify_file')
        redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
        return nil
      end

      upload = if params[:local_file].present?
                 local_file_ingest(params[:local_file])
               elsif params[:s3_url].present?
                 s3_file_ingest(params[:s3_url])
               else
                 params[:file].presence
               end

      mime_type = validate_upload(upload)

      {
        file_upload: upload,
        mime_type:   mime_type,
        filename:    params[:file_name].presence || upload.original_filename
      }
    end

    def validate_upload(file_upload)
      mime_type = Validators.file_type(file_upload)
      Validators.validate_file(file_upload, mime_type)
      mime_type
    rescue DRI::Exceptions::UnknownMimeType, DRI::Exceptions::WrongExtension, DRI::Exceptions::InappropriateFileType
      message = t('dri.flash.alert.invalid_file_type')
      flash[:alert] = @warnings = message
      mime_type
    rescue DRI::Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      raise DRI::Exceptions::BadRequest,
        t('dri.views.exceptions.invalid_file', name: file_upload&.original_filename || params[:file_name].presence)
    end

    def local_file_ingest(name)
      File.new(Rails.root.join(Settings.dri.uploads, name))
    end

    def s3_file_ingest(name)
      bucket   = name.split('/')[-2]
      key      = params[:file_name]
      download = Tempfile.new([key[/^(.*?)\./,1], File.extname(key)])
      storage  = StorageService.new

      if storage.download_file(bucket, key, download)
        storage.delete_file(bucket, key)
        download
      else
        raise DRI::Exceptions::InternalError
      end
    end

    def send_file_with_range(path, options = {})
      file_size    = File.size(path)
      begin_point  = 0
      end_point    = file_size - 1
      status       = 200

      if request.headers['range'] =~ /bytes\=(\d+)\-(\d*)/
        status      = 206
        begin_point = $1.to_i
        end_point   = $2.to_i if $2.present?
      end

      content_length = end_point - begin_point + 1
      response.header['Content-Range']  = "bytes #{begin_point}-#{end_point}/#{file_size}"
      response.header['Content-Length'] = content_length.to_s
      send_data IO.binread(path, content_length, begin_point), options.merge(status: status)
    end
end