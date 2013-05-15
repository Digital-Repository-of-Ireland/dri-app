# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class FilesController < AssetsController

  require 'validators'
  require 'background_tasks/queue_manager'

  # Returns the directory on the local filesystem to use for storing uploaded files.
  #
  def local_storage_dir
    Rails.root.join(Settings.dri.files)
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the file in the masterContent datastream
  #      
  def show
    datastream = "masterContent"
    @object = retrieve_object params[:id]

    @local_file_info = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d",
                                                                { :f => @object.id, :d => datastream } ],
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

    render :text => "Unable to find file"
  end

  # Stores an uploaded file to the local filesystem and then attaches it to one
  # of the objects datastreams. masterContent is used by default.
  #
  def create
    datastream = "masterContent"
    if params.has_key?(:datastream)
      datastream = params[:datastream]
    end

    if !params.has_key?(:Filedata) || params[:Filedata].nil?
      flash[:notice] = t('dri.flash.notice.specify_file')
      redirect_to :controller => "catalog", :action => "show", :id => params[:id]
      return
    end

    file_upload = params[:Filedata]

    if datastream.eql?("masterContent")
      @object = retrieve_object params[:id]

      if @object == nil
        flash[:notice] = t('dri.flash.notice.specify_object_id')
      else
        begin
          Validators.validate_file(file_upload, @object.whitelist_type, @object.whitelist_subtypes)
        rescue Exceptions::UnknownMimeType, Exceptions::WrongExtension, Exceptions::InappropriateFileType
          message = t('dri.flash.alert.invalid_file_type')
          flash[:alert] = message
          @warnings = message
        rescue Exceptions::VirusDetected => e
          flash[:error] = t('dri.flash.alert.virus_detected', :virus => e.message)
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_file', :name => file_upload.original_filename)
          return
        end
        
        create_file(file_upload, @object.id, datastream, params[:checksum])
        start_background_tasks
        
        @url = url_for :controller=>"files", :action=>"show", :id=>params[:id]
        logger.error @action_url
        @object.add_file_reference datastream, :url=>@url, :mimeType=>@file.mime_type

        begin
          raise Exceptions::InternalError unless @object.save!
        rescue RuntimeError => e
          logger.error "Could not save object #{@object.id}: #{e.message}"
          raise Exceptions::InternalError
        end

        flash[:notice] = t('dri.flash.notice.file_uploaded')

        respond_to do |format|
          format.html {redirect_to :controller => "catalog", :action => "show", :id => params[:id]}
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

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

  private

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

    def start_background_tasks
      queue = BackgroundTasks::QueueManager.new()
      queue.process(@object)
    end

end 
