# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController

  require 'validators'

  # Returns the directory on the local filesystem to use for storing uploaded files.
  #
  def local_storage_dir
    Rails.root.join(Settings.dri.files)
  end

  def actor
    @actor ||= DRI::Asset::Actor.new(@generic_file, current_user)
  end

  def show
    datastream = params[:datastream].presence || "content"

    @document = retrieve_object! params[:object_id]
    @generic_file = retrieve_object! params[:id]

    can_view?

    respond_to do |format|
      format.html
      format.json  { render :json => @generic_file }
    end

  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the file in the content datastream
  def download
    # Check if user can view a master file
    enforce_permissions!("edit", params[:object_id]) if params[:version].present?

    @generic_file = retrieve_object! params[:id]
    unless @generic_file.nil?
      can_view?

      if local_file
        logger.error "Using path: "+local_file.path
        response.headers['Content-Length'] = File.size?(local_file.path).to_s
        send_file local_file.path,
                      :type => local_file.mime_type,
                      :stream => true,
                      :buffer => 4096,
                      :disposition => "attachment; filename=\"#{File.basename(local_file.path)}\";",
                      :url_based_filename => true
        return
      end
    end

    render :text => "Unable to find file"
  end

  def update
    enforce_permissions!("edit", params[:object_id])

    datastream = params[:datastream].presence || "content"

    file_upload = upload_from_params

    if datastream.eql?("content")
      @generic_file = retrieve_object! params[:id]

      version = actor.version_number(datastream)
      create_file(file_upload, @generic_file, datastream, version, params[:checksum])

      url = url_for :controller=>"assets", :action=>"download", :object_id => @generic_file.batch.id, :id=>@generic_file.id

      if actor.update_external_content(URI.escape(url), file_upload, datastream)
        flash[:notice] = t('dri.flash.notice.file_uploaded')
      else 
        message = @generic_file.errors.full_messages.join(', ')
        flash[:alert] = t('dri.flash.alert.error_saving_file', :error => message)
        @warnings = t('dri.flash.alert.error_saving_file', :error => message)
        logger.error "Error saving file: #{message}"
      end

      respond_to do |format|
        format.html {redirect_to object_file_url(params[:object_id], @generic_file.id)}
        format.json  {
          if @warnings
            response = { :checksum => @file.checksum, :warning => @warnings }
          else
            response = { :checksum => @file.checksum }
          end
            render :json => response, :status => :ok
        }
      end
      return
    else
      flash[:notice] = t('dri.flash.notice.specify_datastream')
    end

    redirect_to object_file_url(params[:object_id], params[:id])
  end

  # Stores an uploaded file to the local filesystem and then attaches it to one
  # of the objects datastreams. content is used by default.
  #
  def create
    enforce_permissions!("edit", params[:object_id])

    datastream = params[:datastream].presence || "content"

    file_upload = upload_from_params

    if datastream.eql?("content")
      @object = retrieve_object! params[:object_id]

      if @object == nil
        flash[:notice] = t('dri.flash.notice.specify_object_id')
      else
        @generic_file = DRI::GenericFile.new(id: Sufia::IdService.mint)
        @generic_file.batch = @object
        @generic_file.apply_depositor_metadata(current_user)
        @generic_file.preservation_only = "true" if params[:preservation].eql?('true')
        
        version = actor.version_number(datastream)
        create_file(file_upload, @generic_file, datastream, version, params[:checksum])

        url = url_for :controller=>"assets", :action=>"download", :object_id => @object.id, :id=>@generic_file.id

        if actor.create_external_content(URI.escape(url), datastream, file_upload.original_filename)
          flash[:notice] = t('dri.flash.notice.file_uploaded')
        else
          message = @generic_file.errors.full_messages.join(', ')
          flash[:alert] = t('dri.flash.alert.error_saving_file', :error => message)
          @warnings = t('dri.flash.alert.error_saving_file', :error => message)
          logger.error "Error saving file: #{message}"
        end

        respond_to do |format|
          format.html {redirect_to :controller => "catalog", :action => "show", :id => params[:object_id]}
          format.json  {
            if @warnings
              response = { :checksum => @file.checksum, :warning => @warnings }
            else
              response = { :checksum => @file.checksum }
            end
            render :json => response, :status => :created
          }
        end
        return
      end
    else
      flash[:notice] = t('dri.flash.notice.specify_datastream')
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:object_id]
  end


  # API call: takes one or more object ids and returns a list of asset urls
  def list_assets

    @list = []

    if params[:objects].present?

      solr_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(params[:objects].map{|o| o.values.first})
      result_docs = Solr::Query.new(solr_query)

      storage = Storage::S3Interface.new

      while result_docs.has_more?
        doc = result_docs.pop

        doc.each do |r|
          doc = SolrDocument.new(r)

          files_query = "#{ActiveFedora::SolrQueryBuilder.solr_name('isPartOf', :stored_searchable, type: :symbol)}:\"#{doc.id}\""
          query = Solr::Query.new(files_query)

          item = {}
          item['pid'] = doc.id
          item['files'] = []

          while query.has_more?
            files = query.pop

            files.each do |mf|
              file_list = {}
              file_doc = SolrDocument.new(mf)

              if (doc.read_master? && can?(:read, doc)) || can?(:edit, doc)
                url = url_for(file_download_url(doc.id, file_doc.id))
                file_list['masterfile'] = url
              end

              if can? :read, doc
                surrogates = storage.get_surrogates doc, file_doc
                surrogates.each do |file,loc|
                  file_list[file] = loc
                end
              end

              item['files'].push(file_list)
            end
          end
          @list << item
        end
      end

      raise Exceptions::NotFound if @list.empty?

    else
      raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.json
    end
  end


  private

    def can_view?
      if !(@generic_file.public? && can?(:read, params[:object_id])) && !can?(:edit, params[:object_id])
        raise Hydra::AccessDenied.new("This item is not available. You do not have sufficient access privileges to view the master file(s).", :read_master, params[:object_id])
      end
    end

    def upload_from_params
      if params[:Filedata].blank? && params[:Presfiledata].blank?
        flash[:notice] = t('dri.flash.notice.specify_file')
        redirect_to :controller => "catalog", :action => "show", :id => params[:object_id]
        return
      end

      if params[:Filedata].present?
        file_upload = params[:Filedata]
      elsif params[:Presfiledata].present?
        file_upload = params[:Presfiledata]
      end

      validate_upload(file_upload)

      file_upload
    end


    def validate_upload(file_upload)
      begin
        @mime_type = Validators.file_type?(file_upload)
        Validators.validate_file(file_upload, @mime_type)
      rescue Exceptions::UnknownMimeType, Exceptions::WrongExtension, Exceptions::InappropriateFileType
        message = t('dri.flash.alert.invalid_file_type')
        flash[:alert] = message
        @warnings = message
      rescue Exceptions::VirusDetected => e
        flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
        raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_file', :name => file_upload.original_filename)
        return
      end
    end

    def build_path(generic_file, datastream, version)
      File.join(generic_file.id, datastream+version.to_s)
    end

    def create_file(filedata, generic_file, datastream, version, checksum)
      dir = local_storage_dir.join(build_path(generic_file, datastream, version))

      @file = LocalFile.new
      @file.add_file filedata, {:fedora_id => generic_file.id, :ds_id => datastream, :directory => dir.to_s, :version => version, :mime_type => @mime_type, :checksum => checksum}

      begin
        raise Exceptions::InternalError unless @file.save!
      rescue ActiveRecord::ActiveRecordError => e
        logger.error "Could not save the asset file #{@file.path} for #{generic_file.id} to #{datastream}: #{e.message}"
        raise Exceptions::InternalError
      end
    end

    def local_file
      if (params[:version].present?)
        LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d AND version = :v",
                       { :f => @generic_file.id, :d => @datastream, :v => params[:version] }).take
      else
        LocalFile.where("fedora_id LIKE :f AND ds_id LIKE :d",
                       { :f => @generic_file.id, :d => @datastream }).order("version DESC").take
      end
    end

    def save_file
      begin
        raise Exceptions::InternalError unless @gf.save!
      rescue RuntimeError => e
        logger.error "Could not save file #{@gf.id}: #{e.message}"
        raise Exceptions::InternalError
      end
    end

end
