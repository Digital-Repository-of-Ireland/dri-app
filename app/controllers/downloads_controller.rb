class DownloadsController < ApplicationController
 include Hydra::AccessControlsEnforcement
 include DRI::Metadata
 include DRI::Model

 #before_filter :enforce_edit_permissions, :except => [:show_metadata, :show_file, :ingest_metadata]

 def local_storage_dir
   Rails.root.join('dri_files')
 end 

 # Renders the metadata XML stored in the descMetadata datastream.
 #
 # 
 def show_metadata
   @object = retrieve_object params[:id]

     if @object && @object.datastreams.keys.include?("descMetadata")
       render :xml => @object.datastreams["descMetadata"].content
       return
     end

     render :text => "Unable to load metadata"
 end

 # Retrieves external datastream files that have been stored in the filesystem.
 # By default, it retrieves the file in the masterContent datastream
 #
 # 
 def show_file
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

 # Uploads a file to the storage system, while recording it's location
 # in the relevant datastream
 #
 #
 def upload_file
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

          @url = url_for :controller=>"downloads", :action=>"show_file", :id=>params[:id]
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

 # Replaces the metadata of an object with uploaded XML file.
 #
 #
 def replace_metadata
   
   if params.has_key?(:metadata_file) && params[:metadata_file] != nil
	if is_valid_dc?
          @object = retrieve_object params[:id]

          if @object == nil
            flash[:notice] = "Please specify a valid object id."
          else
	    # ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
            # ds.dsid = "descMetadata"
            # @object.add_datastream(ds)

	    if @object.datastreams.has_key?("descMetadata")
              @object.datastreams["descMetadata"].ng_xml = @tmp_xml
            else
	      ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
              @object.add_datastream ds, :dsid => 'descMetadata'
            end

	     @object.datastreams["descMetadata"].save
	     @object.save

            flash[:notice] = "Metadata has been successfully updated."
          end
        end
    else
      flash[:notice] = "You must specify a valid file to upload."
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
 end

 # Ingests the metadata of XML file to create a new digital object.
 #
 #
 def ingest_metadata
  
   if params.has_key?(:metadata_file) && params[:metadata_file] != nil
        if is_valid_dc?
          @object = DRI::Model::Audio.new

            if @object.datastreams.has_key?("descMetadata")
              @object.datastreams["descMetadata"].ng_xml = @tmp_xml
            else
              ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
              @object.add_datastream ds, :dsid => 'descMetadata'
            end

            # @object.datastreams["descMetadata"].save
            @object.save
            flash[:notice] = "Audio object has been successfully ingested."
            redirect_to :controller => "catalog", :action => "show", :id => @object.id
            return
        end
    else
      flash[:notice] = "You must specify a valid file to upload."
    end

    redirect_to :controller => "audios", :action => "new"
 end

 def retrieve_object(id)
   return objs = ActiveFedora::Base.find(id,{:cast => true})
 end

 def is_valid_dc?
   result = false

   if MIME::Types.type_for(params[:metadata_file].original_filename).first.content_type.eql? 'application/xml'
     tmp = params[:metadata_file].tempfile
     @tmp_xml = Nokogiri::XML(tmp.read)

     namespace = @tmp_xml.namespaces

     if namespace.has_key?("xmlns:oai_dc") &&
	namespace.has_key?("xmlns:dc") &&
	namespace["xmlns:oai_dc"].eql?("http://www.openarchives.org/OAI/2.0/oai_dc/") &&
	namespace["xmlns:dc"].eql?("http://purl.org/dc/elements/1.1/")

       validate_errors = @tmp_xml.validate

       if validate_errors == nil || validate_errors.size == 0
	 result = true
       else
	 flash[:notice] = "Validation Errors: "+validate_errors
       end
     else
       flash[:notice] = "The XML file could not validate against the Dublin Core schema"
     end
   else
     flash[:notice] = "You must specify a XML file."	
   end

   return result
 end
end
