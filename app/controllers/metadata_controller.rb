class MetadataController < AssetsController

  # Renders the metadata XML stored in the descMetadata datastream.
  #
  # 
  def show
    @object = retrieve_object params[:id]

    if @object && @object.datastreams.keys.include?("descMetadata")
       render :xml => @object.datastreams["descMetadata"].content
       return
    end

    render :text => "Unable to load metadata"
  end

  def update 

    if params.has_key?(:metadata_file) && params[:metadata_file] != nil
      if is_valid_dc?
        @object = retrieve_object params[:id]

        if @object == nil
          flash[:notice] = "Please specify a valid object id."
        else
            
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
  def create

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

      if namespace.has_key?("xmlns:dcterms") &&
        namespace.has_key?("xmlns:dc") &&
        namespace["xmlns:dcterms"].eql?("http://purl.org/dc/terms/") &&
        namespace["xmlns:dc"].eql?("http://purl.org/dc/elements/1.1/")

        #xsd_xml = "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
        #xsd = Nokogiri::XML::Schema(open(xsd_xml))
        validate_errors = @tmp_xml.validate #xsd.validate(@tmp_xml)

        if validate_errors == nil || validate_errors.size == 0
          result = true
        else
          flash[:notice] = "Validation Errors: #{validate_errors.join(", ")}"
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
