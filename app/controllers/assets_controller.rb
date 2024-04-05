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
  include DRI::Asset::MimeTypes

  def new
    enforce_permissions!('edit', params[:object_id])

    @document = SolrDocument.find(params[:object_id])
  end

  def index
    enforce_permissions!('edit', params[:object_id])

    @document = SolrDocument.find(params[:object_id])
    @assets = @document.assets(with_preservation: true, ordered: true)
    @status = @document.assets_status_info(@assets)
  end

  def show
    @document = SolrDocument.find(params[:object_id])
    can_view?

    @presenter = DRI::ObjectInMyCollectionsPresenter.new(@document, view_context)
    @generic_file = retrieve_object! params[:id]

    @status = @document.ingest_status_info(@generic_file.alternate_id)

    respond_to do |format|
      format.html
      format.json { render json: @generic_file }
    end
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  def download
    @generic_file = retrieve_object! params[:id]
    
    unless @generic_file && File.file?(@generic_file.path)
      raise DRI::Exceptions::NotFound
    end
   
    @document = SolrDocument.find(params[:object_id])
    can_view?

    response.header['Accept-Ranges'] = 'bytes'
    if request.headers['range']
      send_file_with_range @generic_file.path,
          type: @generic_file.mime_type || 'application/octet-stream',
          disposition: 'inline'
    else
      response.headers['Content-Length'] = File.size?(@generic_file.path).to_s
      send_file @generic_file.path,
          type: @generic_file.mime_type || 'application/octet-stream',
          stream: true,
          buffer: 4096,
          disposition: "attachment; filename=\"#{@generic_file.filename.first}\";"
    end
  end

  def destroy
    enforce_permissions!('edit', params[:object_id])

    object = retrieve_object!(params[:object_id])
    generic_file = retrieve_object!(params[:id])

    if object.status == 'published' && !current_user.is_admin?
      raise Blacklight::AccessControls::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '')
    end

    begin
      DRI::GenericFile.transaction do
        delete_surrogates(params[:object_id], generic_file.alternate_id)
        generic_file.destroy!
      end

      object.increment_version
      object.save!
      record_version_committer(object, current_user)
      if object.status == "published"
        new_doi(object, 'asset modified')
        mint_or_update_doi(object)
      end

      # Do the preservation actions
      delfiles = ["#{generic_file.alternate_id}_#{generic_file.label}"]
      preservation = Preservation::Preservator.new(object)
      preservation.preserve_assets({ deleted: { 'content' => delfiles }})

      flash[:notice] = t('dri.flash.notice.asset_deleted')
    rescue RuntimeError => e
      logger.error "Could not delete file #{generic_file.alternate_id}: #{e.message}"
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: e.message)
    end

    respond_to do |format|
      format.html { redirect_to object_files_path(object) }
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    file_upload = upload_from_params

    @object = retrieve_object! params[:object_id]
    @generic_file = @object.generic_files.joins(:alternate_identifier).find_by(dri_identifiers: { alternate_id: params[:id] })

    file_content = GenericFileContent.new(user: current_user, object: @object, generic_file: @generic_file)
    begin
      @object.increment_version

      if file_content.update_content(file_upload)
        flash[:notice] = t('dri.flash.notice.file_uploaded')
        record_version_committer(@object, current_user)
        file_content.characterize if file_content.has_content?
      else
        message = @generic_file.errors.full_messages.join(', ')
        flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
        logger.error "Error saving file: #{message}"
      end
    rescue DRI::Exceptions::MoabError => e
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: e.message)
      @warnings = t('dri.flash.alert.error_saving_file', error: e.message)
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

  # Stores an uploaded file to the local filesystem and then attaches it to
  # a new GenericFile.
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
    begin
      @object.increment_version

      if file_content.add_content(file_upload)
        record_version_committer(@object, current_user)
        file_content.characterize if file_content.has_content?
        @message = t('dri.flash.notice.file_uploaded')
        @status = :created
      else
        error_message = @generic_file.errors.full_messages.join(', ')     
        @warnings = t('dri.flash.alert.error_saving_file', error: error_message)
        @status = :internal_server_error
        logger.error "Error saving file: #{error_message}"
      end
    rescue DRI::Exceptions::MoabError => e
      @warnings = t('dri.flash.alert.error_saving_file', error: e.message)
      @status = :internal_server_error
      logger.error "Error saving file: #{e.message}"
    end

    respond_to do |format|
      format.html do
        flash[:notice] = @message if @message
        flash[:alert] = @warnings if @warnings
        redirect_to controller: 'my_collections', action: 'show', id: params[:object_id]
      end
      format.json do
        response = {}
        response[:warnings] = @warnings if @warnings
        response[:messages] = @message if @message && @status == :created
        render json: response, status: @status
      end
    end
  end

  private

    def build_generic_file(object:, user:, preservation: false)
      generic_file = DRI::GenericFile.new(alternate_id: DRI::Noid::Service.new.mint)
      generic_file.digital_object = object
      generic_file.apply_depositor_metadata(user)
      generic_file.preservation_only = 'true' if preservation

      generic_file
    end

    def can_view?
      if (!viewable? && !editor?)
        raise Blacklight::AccessControls::AccessDenied.new(
          t('dri.views.exceptions.view_permission'),
          :read_master,
          params[:object_id]
        )
      end
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
      storage = StorageService.new
      storage.delete_surrogates(bucket_name, file_prefix)
    end

    def local_file_ingest(name)
      upload_dir = Rails.root.join(Settings.dri.uploads)
      File.new(File.join(upload_dir, name))
    end

    def send_file_with_range(path, options = {})
      file_size = File.size(path)
      begin_point = 0
      end_point = file_size - 1
      status = 200
      if request.headers['range']
        status = 206
        if request.headers['range'] =~ /bytes\=(\d+)\-(\d*)/
          begin_point = $1.to_i
          end_point = $2.to_i if $2.present?
        end
      end
      content_length = end_point - begin_point + 1
      response.header['Content-Range'] = "bytes #{begin_point}-#{end_point}/#{file_size}"
      response.header['Content-Length'] = content_length.to_s
      send_data IO.binread(path, content_length, begin_point), options.merge(:status => status)
    end

    def upload_from_params
      if params[:file].blank? && params[:local_file].blank?
        flash[:notice] = t('dri.flash.notice.specify_file')
        redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
        return
      end

      upload = if params[:local_file].present?
                 local_file_ingest(params[:local_file])
               else
                 params[:file].presence
               end

      mime_type = validate_upload(upload)

      { 
        file_upload: upload,
        mime_type: mime_type,
        filename: params[:file_name].presence || upload.original_filename
      }
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
