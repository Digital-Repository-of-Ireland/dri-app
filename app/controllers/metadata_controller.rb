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

        # We have to extract all the schemata from the XML Document in order to validate correctly
        schema_imports = []

        # Firstly, if the root schema has no namespace, retrieve it from xsi:noNamespaceSchemaLocation
        if (@tmp_xml.root.namespace == nil)
          schema_imports = ["<xs:include schemaLocation=\""+@tmp_xml.root.attr("xsi:noNamespaceSchemaLocation")+"\"/>\n"]
        end
        
        # Then, find all elments that have the "xsi:schemaLocation" attribute and retrieve their namespace and schemaLocation
        @tmp_xml.xpath("//*[@xsi:schemaLocation]").each do |node|
          schemata_by_ns = Hash[node.attr("xsi:schemaLocation").scan(/(\S+)\s+(\S+)/)]
          schemata_by_ns.each do |ns,loc|
	    schema_imports = schema_imports | ["<xs:import namespace=\""+ns+"\" schemaLocation=\""+loc+"\"/>\n"]
          end
        end

        if (schema_imports.size == 0)
          flash[:notice] = "The XML file contains no schema to validate against."
        else
          # Create a schema that imports and includes the schema used in the XML

          all_schemata = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n" +
  			"<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" elementFormDefault=\"qualified\">\n" +
                        schema_imports.join("") + "</xs:schema>"

	  # When parsing the schema, the local directory needs to point to the schema folder
          # as a work around to the problem Nokogiri has with parsing relative path imports.
          xsd = Dir.chdir(Rails.root.join('config').join('schemas')) do |path|
             Nokogiri::XML::Schema(all_schemata)
          end

          validate_errors = xsd.validate(@tmp_xml)

          if validate_errors == nil || validate_errors.size == 0
	    result = true
          else
            flash[:error] = "Validation Errors:<br/>".html_safe+validate_errors.join("<br/>").html_safe
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
