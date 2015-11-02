# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#

require 'preservation/preservator'
require 'validators'

class AssetsController < ApplicationController

  before_filter :authenticate_user_from_token!, only: [:list_assets]
  before_filter :authenticate_user!, only: [:list_assets]

  include DRI::Doi

  def actor
    @actor ||= DRI::Asset::Actor.new(@generic_file, current_user)
  end

  def show
    datastream = params[:datastream].presence || 'content'

    @document = retrieve_object! params[:object_id]
    @generic_file = retrieve_object! params[:id]

    status(@generic_file.id)

    can_view?

    respond_to do |format|
      format.html
      format.json { render json: @generic_file }
    end

  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the file in the content datastream
  def download
    # Check if user can view a master file
    enforce_permissions!('edit', params[:object_id]) if params[:version].present?

    @generic_file = retrieve_object! params[:id]
    if @generic_file
      can_view?

      @datastream = params[:datastream].presence || 'content'

      if local_file
        response.headers['Content-Length'] = File.size?(local_file.path).to_s
        send_file local_file.path,
                  type: local_file.mime_type,
                  stream: true,
                  buffer: 4096,
                  disposition: "attachment; filename=\"#{File.basename(local_file.path)}\";",
                  url_based_filename: true
        return
      end
    end

    render text: 'Unable to find file', status: 500
  end

  def destroy
    enforce_permissions!('edit', params[:object_id])

    @generic_file = retrieve_object!(params[:id])

    raise Hydra::AccessDenied.new(t('dri.flash.alert.delete_permission'), :delete, '') if @generic_file.batch.status == 'published'

    @generic_file.delete
    delete_surrogates(params[:object_id], @generic_file.id)

    flash[:notice] = t('dri.flash.notice.asset_deleted')

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: params[:object_id] }
    end
  end

  def update
    enforce_permissions!('edit', params[:object_id])

    datastream = params[:datastream].presence || 'content'
    unless datastream.eql?('content')
      flash[:notice] = t('dri.flash.notice.specify_datastream')
      return redirect_to object_file_url(params[:object_id], params[:id])
    end

    file_upload = upload_from_params
    @generic_file = retrieve_object! params[:id]

    create_file(file_upload, @generic_file, datastream, params[:checksum], params[:file_name])

    if actor.update_external_content(URI.escape(download_url), file_upload, datastream)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      object = @generic_file.batch
      mint_doi(object, 'asset modified') if object.status == 'published'
    else
      message = @generic_file.errors.full_messages.join(', ')
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
      logger.error "Error saving file: #{message}"
    end

    respond_to do |format|
      format.html { redirect_to object_file_url(params[:object_id], @generic_file.id) }
      format.json {
        response = { checksum: @file.checksum }
        response[:warning] = @warnings if @warnings

        render json: response, status: :ok
      }
    end
  end

  # Stores an uploaded file to the local filesystem and then attaches it to one
  # of the objects datastreams. content is used by default.
  #
  def create
    enforce_permissions!('edit', params[:object_id])

    datastream = params[:datastream].presence || 'content'
    unless datastream == 'content'
      flash[:notice] = t('dri.flash.notice.specify_datastream')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    file_upload = upload_from_params

    @object = retrieve_object! params[:object_id]
    if @object.nil?
      flash[:notice] = t('dri.flash.notice.specify_object_id')
      return redirect_to controller: 'catalog', action: 'show', id: params[:object_id]
    end

    @generic_file = DRI::GenericFile.new(id: ActiveFedora::Noid::Service.new.mint)
    @generic_file.batch = @object
    @generic_file.apply_depositor_metadata(current_user)
    @generic_file.preservation_only = 'true' if params[:preservation] == 'true'

    create_file(file_upload, @generic_file, datastream, params[:checksum], params[:file_name])

    filename = params[:file_name].presence || file_upload.original_filename

    if actor.create_external_content(URI.escape(download_url), datastream, filename)
      flash[:notice] = t('dri.flash.notice.file_uploaded')

      mint_doi(@object, 'asset added') if @object.status == 'published'
    else
      message = @generic_file.errors.full_messages.join(', ')
      flash[:alert] = t('dri.flash.alert.error_saving_file', error: message)
      @warnings = t('dri.flash.alert.error_saving_file', error: message)
      logger.error "Error saving file: #{message}"
    end

    respond_to do |format|
      format.html { redirect_to controller: 'catalog', action: 'show', id: params[:object_id] }
      format.json  {
        response = { checksum: @file.checksum }
        response[:warnings] = @warnings if @warnings

        render json: response, status: :created
      }
    end
  end

  # API call: takes one or more object ids and returns a list of asset urls
  def list_assets
    @list = []

    raise Exceptions::BadRequest unless params[:objects].present?

    solr_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(params[:objects].map{ |o| o.values.first })
    result_docs = Solr::Query.new(solr_query)
    result_docs.each_solr_document do |doc|
      item = list_files_with_surrogates(doc)
      @list << item unless item.empty?
    end

    raise Exceptions::NotFound if @list.empty?

    respond_to do |format|
      format.json
    end
  end

  private

    def can_view?
      if !(@generic_file.public? && can?(:read, params[:object_id])) && !can?(:edit, params[:object_id])
        raise Hydra::AccessDenied.new('This item is not available. You do not have sufficient access privileges to view the master file(s).', :read_master, params[:object_id])
      end
    end

    def create_file(filedata, generic_file, datastream, checksum, filename = nil)
      # prepare file
      @file = LocalFile.new(fedora_id: generic_file.id, ds_id: datastream)
      options = {}
      options[:mime_type] = @mime_type
      options[:checksum] = checksum
      options[:file_name] = filename unless filename.nil?
      options[:batch_id] = generic_file.batch.id
      options[:object_version] = (generic_file.batch.object_version.to_i+1).to_s

      # Create MOAB dir and files
      preservation = Preservation::Preservator.new(generic_file.batch.id, options[:object_version])
      preservation.create_moab_dirs()
      generic_file.batch.object_version = options[:object_version]
      preservation.moabify_datastream('properties', generic_file.batch.datastreams['properties'])

      # Update object version
      begin
        generic_file.batch.save!
      rescue ActiveRecord::ActiveRecordError => e
        logger.error "Could not update object version number for #{generic_file.batch.id} to version #{options[:object_version]}"
        raise Exceptions::InternalError
      end

      # Add and save the file
      @file.add_file filedata, options

      begin
        @file.save!
      rescue ActiveRecord::ActiveRecordError => e
        logger.error "Could not save the asset file #{@file.path} for #{generic_file.id} to #{datastream}: #{e.message}"
        raise Exceptions::InternalError
      end

    end

    def delete_surrogates(bucket_name, file_prefix)
      storage = Storage::S3Interface.new
      storage.delete_surrogates(bucket_name, file_prefix)
    end

    def download_url
      url_for controller: 'assets', action: 'download', object_id: @generic_file.batch.id, id: @generic_file.id
    end

    def list_files_with_surrogates(doc)
      files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{doc.id}\" AND NOT #{ActiveFedora::SolrQueryBuilder.solr_name('dri_properties__preservation_only', :stored_searchable)}:true"
      query = Solr::Query.new(files_query)

      item = {}
      item['pid'] = doc.id
      item['files'] = []

      storage = Storage::S3Interface.new

      query.each_solr_document do |file_doc|
        file_list = {}

        if (doc.read_master? && can?(:read, doc)) || can?(:edit, doc)
          url = url_for(file_download_url(doc.id, file_doc.id))
          file_list['masterfile'] = url
        end

        if can? :read, doc
          surrogates = storage.get_surrogates doc, file_doc
          surrogates.each { |file, loc| file_list[file] = loc }
        end

        item['files'].push(file_list)
      end

      item
    end

    def local_file
      search_params = { f: @generic_file.id, d: @datastream }
      search_params[:v] = params[:version] if params[:version].present?

      query = 'fedora_id LIKE :f AND ds_id LIKE :d'
      query << ' AND version = :v' if search_params[:v].present?

      LocalFile.where(query, search_params).take
    rescue ActiveRecord::RecordNotFound
      raise Exceptions::InternalError, 'Unable to find requested file'
    rescue ActiveRecord::ActiveRecordError
      raise Exceptions::InternalError, 'Error finding file'
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

      if params[:Filedata].present?
        file_upload = params[:Filedata]
      elsif params[:Presfiledata].present?
        file_upload = params[:Presfiledata]
      elsif params[:local_file].present?
        file_upload = local_file_ingest(params[:local_file])
      end

      validate_upload(file_upload)

      file_upload
    end

    def validate_upload(file_upload)
      @mime_type = Validators.file_type?(file_upload)
      Validators.validate_file(file_upload, @mime_type)
    rescue Exceptions::UnknownMimeType, Exceptions::WrongExtension, Exceptions::InappropriateFileType
      message = t('dri.flash.alert.invalid_file_type')
      flash[:alert] = message
      @warnings = message
    rescue Exceptions::VirusDetected => e
      flash[:error] = t('dri.flash.alert.virus_detected', virus: e.message)
      raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_file', name: file_upload.original_filename)
    end

end
