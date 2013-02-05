# Creates, updates, or retrieves files attached to the objects masterContent datastream.
#
class FilesController < AssetsController

  require 'validators'

  # Returns the directory on the local filesystem to use for storing uploaded files.
  #
  def local_storage_dir
    Rails.root.join('dri_files')
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

    if params.has_key?(:Filedata) && params[:Filedata] != nil
      if datastream.eql?("masterContent")
        @object = retrieve_object params[:id]

        if @object == nil
          flash[:notice] = t('dri.flash.notice.speficy_object_id')
        else
          count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => @object.id, :d => datastream } ]).count

          unless Validators.valid_file_type?(params[:Filedata], @object.whitelist_type, @object.whitelist_subtypes)
            flash[:alert] = t('dri.flash.alert.invalid_file_type')
          end

          dir = local_storage_dir.join(@object.id).join(datastream+count.to_s)

          @file = LocalFile.new
          @file.add_file params[:Filedata], {:fedora_id => @object.id, :ds_id => datastream, :directory => dir.to_s, :version => count}
          @file.save!

          @url = url_for :controller=>"files", :action=>"show", :id=>params[:id]
          logger.error @action_url
          @object.add_file_reference datastream, :url=>@url, :mimeType=>@file.mime_type
          @object.save

          flash[:notice] = t('dri.flash.notice.file_uploaded')

        end
      else
        flash[:notice] = t('dri.flash.notice.specify_datastream')
      end
    else
      flash[:notice] = t('dri.flash.notice.specify_file')
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

end 
