#
# Creates, updates, or retrieves, the descMetadata datastream for an object
# 
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

  # Replaces the current descMetadata datastream with the contents of the uploaded XML file.
  #
  #
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

            if @object.is_a?(DRI::Model::Audio)
              ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
            elsif @object.is_a?(DRI::Model::Pdfdoc)
              ds = DRI::Metadata::DublinCorePdfdoc.from_xml(@tmp_xml)
            end

            @object.add_datastream ds, :dsid => 'descMetadata'
          end

           @object.datastreams["descMetadata"].save

           if @object.valid?
             @object.save
             flash[:notice] = "Metadata has been successfully updated."
           else
             flash[:alert] = "Invalid Object: #{@object.errors.full_messages.inspect}."
           end
        end
      end
    else
      flash[:notice] = "You must specify a valid file to upload."
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

  # Ingests metadata from an XML file to create a new digital object.
  #
  #
  def create

    if params.has_key?(:metadata_file) && params[:metadata_file] != nil
      if is_valid_dc?

        if !session[:ingest][:type].nil? && !session[:ingest][:type].blank?
          @object = DRI::Model::DigitalObject.construct(session[:ingest][:type].to_sym, session[:object_params])
        else 
          @object = DRI::Model::Audio.new
        end

          if @object.datastreams.has_key?("descMetadata")
            @object.datastreams["descMetadata"].ng_xml = @tmp_xml
          else
            ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
            @object.add_datastream ds, :dsid => 'descMetadata'
          end

          if !session[:ingest][:collection].nil? && !session[:ingest][:collection].eql?("")
            @object.add_relationship(:is_member_of, Collection.find(session[:ingest][:collection]))
          end

          # @object.datastreams["descMetadata"].save
          if @object.valid?
            @object.save
            flash[:notice] = "Digital object has been successfully ingested."
          else
            flash[:alert] = "Invalid Object: #{@object.errors.full_messages.inspect}."
            redirect_to :controller => "ingest", :action => "new"
            return
          end

          redirect_to :controller => "catalog", :action => "show", :id => @object.id
          return
      end
    else
      flash[:notice] = "You must specify a valid file to upload."
    end

    redirect_to :controller => "ingest", :action => "new"
  end  

  # Validates Dublin Core metadata against schema declared in the namespace.
  #
  #
  def is_valid_dc?
    result = false

    if MIME::Types.type_for(params[:metadata_file].original_filename).first.content_type.eql? 'application/xml'
      tmp = params[:metadata_file].tempfile
  
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
          no_ns_schema_location = map_to_localfile(@tmp_xml.root.attr("xsi:noNamespaceSchemaLocation"))
          schema_imports = ["<xs:include schemaLocation=\""+no_ns_schema_location+"\"/>\n"]
        end
        
        # Then, find all elments that have the "xsi:schemaLocation" attribute and retrieve their namespace and schemaLocation
        @tmp_xml.xpath("//*[@xsi:schemaLocation]").each do |node|
          schemata_by_ns = Hash[node.attr("xsi:schemaLocation").scan(/(\S+)\s+(\S+)/)]
          schemata_by_ns.each do |ns,loc|
            loc = map_to_localfile(loc)
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

  # Maps a URI to a local filename if the file is found in config/schemas. Otherwise returns the original URI.
  # 
  def map_to_localfile(uri)    
    filename = URI.parse(uri).path[%r{[^/]+\z}]
    file = Rails.root.join('config').join('schemas', filename)
    if Pathname.new(file).exist?
      location = filename 
    else
      location = uri
    end

    return location
  end

end
