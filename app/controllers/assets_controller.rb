# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class AssetsController < ApplicationController

  require 'validators'

  # Returns the directory on the local filesystem to use for storing uploaded files.
  #
  def local_storage_dir
    Rails.root.join(Settings.dri.files)
  end

  def show

    datastream = "content"
    if params.has_key?(:datastream)
      datastream = params[:datastream]
    end

    # Check if user can view a master file
    if (datastream == "content")
      enforce_permissions!("show_master", params[:object_id])
    end

    @document = retrieve_object! params[:object_id]
    @generic_file = retrieve_object! params[:id]

    respond_to do |format|
      format.html
      format.json  { render :json => @generic_file }
    end

  end
  
  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the file in the content datastream
  def download

    datastream = "content"
    if params.has_key?(:datastream)
      datastream = params[:datastream]
    end

    # Check if user can view a master file
    if (datastream == "content")
      enforce_permissions!("show_master", params[:object_id])
    end

    @gf = retrieve_object! params[:id]

    if (@gf != nil)

      @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                                { :f => @gf.id, :d => datastream } ],
                                            :order => "version DESC",
                                            :limit => 1)

      if !@local_file_info.empty?
        logger.error "Using path: "+@local_file_info[0].path
        send_file @local_file_info[0].path,
                      :type => @local_file_info[0].mime_type,
                      :stream => true,
                      :buffer => 4096,
                      :disposition => 'inline'
        return
      end
    end

    render :text => "Unable to find file"
  end 

  # Stores an uploaded file to the local filesystem and then attaches it to one
  # of the objects datastreams. content is used by default.
  #
  def create
    enforce_permissions!("edit" ,params[:object_id])

    datastream = "content"
    if params.has_key?(:datastream)
      datastream = params[:datastream]
    end

    if !params.has_key?(:Filedata) || params[:Filedata].nil?
      flash[:notice] = t('dri.flash.notice.specify_file')
      redirect_to :controller => "catalog", :action => "show", :id => params[:object_id]
      return
    end

    file_upload = params[:Filedata]

    if datastream.eql?("content")
      @object = retrieve_object! params[:object_id]

      if @object == nil
        flash[:notice] = t('dri.flash.notice.specify_object_id')
      else

        mime_type = Validators.file_type?(file_upload)
        validate_upload(file_upload, mime_type)

        @gf = GenericFile.new(:pid => Sufia::IdService.mint)
        @gf.batch = @object
        @gf.save

        create_file(file_upload, @gf.id, datastream, params[:checksum])

        # A silly workaround, @gf doesn't get assigned a pid until it is saved
        # therefore I have to save it twice, in order to have the pid in the URL being
        # referenced in Fedora.
        #
        # We should look at ActiveFedora::Base to see when exactly assign_pid is called
        # and add the correct id to the url before it's saved, eg. look for <<pid>> in
        # the URL and replace it with the assigned pid.
        @url = url_for :controller=>"assets", :action=>"download", :object_id => @object.id, :id=>@gf.id
        @gf.update_file_reference datastream, :url=>@url, :mimeType=>mime_type.to_s
        begin
          @gf.save
        rescue Exception => e
          flash[:alert] = t('dri.flash.alert.error_saving_file', :error => e.message)
          @warnings = t('dri.flash.alert.error_saving_file', :error => e.message)
          logger.error "Error saving file: #{e.message}"
        end

        flash[:notice] = t('dri.flash.notice.file_uploaded')

        respond_to do |format|
          format.html {redirect_to :controller => "catalog", :action => "show", :id => params[:object_id]}
          format.json  {
            if  !@warnings.nil?
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

    if params.has_key?("objects") && !params[:objects].blank?

      solr_query = ActiveFedora::SolrService.construct_query_for_pids(params[:objects].map{|o| o.values.first})
      result_docs = ActiveFedora::SolrService.query(solr_query)

      if result_docs.empty?
        raise Exceptions::NotFound
      end
      
      storage = Storage::S3Interface.new

      result_docs.each do | r |
        doc = SolrDocument.new(r)

        files_query = "is_part_of_ssim:\"info:fedora/#{doc.id}\""
        files = ActiveFedora::SolrService.query(files_query)

        item = {}
        item['pid'] = doc.id
        item['files'] = []
          
        files.each do |mf|
          file_list = {}
          file_doc = SolrDocument.new(mf)
          
          if can? :read_master, doc
            url = url_for(file_download_url(doc.id, file_doc.id))
            file_list['masterfile'] = url
          end

          surrogates = storage.get_surrogates doc, file_doc
          surrogates.each do |file,loc|
            file_list[file] = loc 
          end

          item['files'].push(file_list)
        end

        @list << item
      end

      storage.close

    else
      raise raise Exceptions::BadRequest
    end

    respond_to do |format|
      format.json  { }
    end
  end


  private

    def validate_upload(file_upload, mime_type)
      begin
        Validators.validate_file(file_upload, mime_type)
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

    def create_file(filedata, object_id, datastream, checksum)
      count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => object_id, :d => datastream } ]).count

      dir = local_storage_dir.join(object_id).join(datastream+count.to_s)

      @file = LocalFile.new
      @file.add_file filedata, {:fedora_id => object_id, :ds_id => datastream, :directory => dir.to_s, :version => count, :checksum => checksum}

      begin
        raise Exceptions::InternalError unless @file.save!
      rescue ActiveRecordError => e
        logger.error "Could not save the asset file #{@file.path} for #{object_id} to #{datastream}: #{e.message}"
        raise Exceptions::InternalError
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
