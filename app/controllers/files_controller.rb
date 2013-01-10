class FilesController < AssetsController

  def local_storage_dir
    Rails.root.join('dri_files')
  end

  # Retrieves external datastream files that have been stored in the filesystem.
  # By default, it retrieves the file in the masterContent datastream
  #
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
  
  def create
    datastream = "masterContent"
    if params.has_key?(:datastream)
      datastream = params[:datastream]
    end

    if params.has_key?(:Filedata) && params[:Filedata] != nil
      if datastream.eql?("masterContent")
        @object = retrieve_object params[:id]

        if @object == nil
          flash[:notice] = "Please specify a valid object id."
        else
          count = LocalFile.find(:all, :conditions => [ "fedora_id LIKE :f AND ds_id LIKE :d", { :f => @object.id, :d => datastream } ]).count

          dir = local_storage_dir.join(@object.id).join(datastream+count.to_s)

          @file = LocalFile.new
          @file.add_file params[:Filedata], {:fedora_id => @object.id, :ds_id => datastream, :directory => dir.to_s, :version => count}
          @file.save!

          @url = url_for :controller=>"files", :action=>"show", :id=>params[:id]
          logger.error @action_url
          @object.add_file_reference datastream, :url=>@url, :mimeType=>@file.mime_type
          @object.save

          flash[:notice] = "File has been successfully uploaded."
        end
      else
        flash[:notice] = "You must specify a valid file datastream."
      end
    else
      flash[:notice] = "You must specify a file to upload."
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

end 
