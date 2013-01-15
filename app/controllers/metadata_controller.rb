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
      #@tmp_xml = Nokogiri::XML(tmp.read)
  
      begin
        @tmp_xml = Nokogiri::XML(tmp.read) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
      rescue Nokogiri::XML::SyntaxError => e
        flash[:alert] = "Invalid XML: #{e}"
        return false
      end

      namespace = @tmp_xml.namespaces

      if namespace.has_key?("xmlns:dc") &&
        namespace["xmlns:dc"].eql?("http://purl.org/dc/elements/1.1/")

        # We have to extract the overall root schema from the XML Document as Dublin Core
        # is designed to work with any custom container schema
        schema_location = nil

        if (@tmp_xml.root.namespace == nil)
          schema_location = @tmp_xml.root.attr("xsi:noNamespaceSchemaLocation")
        elsif (@tmp_xml.root.namespace.href != nil)
          root_ns_href = @tmp_xml.root.namespace.href
          schemata_by_ns = Hash[ @tmp_xml.root.attr("xsi:schemaLocation").scan(/(\S+)\s+(\S+)/) ]
	  schema_location = schemata_by_ns[root_ns_href]
        end

        if (schema_location == nil)
          flash[:notice] = "The XML file contains no schema to validate against."
        else
          # Validation against schema that reference other schema, such as
          # the qualifieddc schema seems to be broken in Nokogiri. So
          # we are temporarily disabling it and allowing all incoming XML
          # to pass validation.
          #
          # xsd = Nokogiri::XML::Schema(open(schema_location))
          # validate_errors = xsd.validate(@tmp_xml)
          validate_errors = nil

          if validate_errors == nil || validate_errors.size == 0
	    result = true
          else
            flash[:alert] = "Validation Errors: #{validate_errors.join(", ")}"
          end
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
