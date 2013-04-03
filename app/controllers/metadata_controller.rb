#
# Creates, updates, or retrieves, the descMetadata datastream for an object
# 
class MetadataController < AssetsController

  # Renders the metadata XML stored in the descMetadata datastream.
  # 
  #
  def show
    begin 
      @object = retrieve_object params[:id]
    rescue ActiveFedora::ObjectNotFoundError => e
      render :xml => { :error => 'Not found' }, :status => 404
      return
    end

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
          flash[:notice] = t('dri.flash.notice.specify_object_id')
        else
            
          if @object.datastreams.has_key?("descMetadata")
            @object.datastreams["descMetadata"].ng_xml = @tmp_xml
          else
            ds = @object.load_from_xml(@tmp_xml)
            @object.add_datastream ds, :dsid => 'descMetadata'
          end


          begin
            raise Exceptions::InternalError unless @object.datastreams["descMetadata"].save
          rescue RuntimeError => e
            logger.error "Could not save descMetadata for object #{@object.id}: #{e.message}"
            raise Exceptions::InternalError
          end

          if @object.valid?
            begin
              raise Exceptions::InternalError unless @object.save
            rescue RuntimeError => e
              logger.error "Could not save object #{@object.id}: #{e.message}"
              raise Exceptions::InternalError
            end

             flash[:notice] = t('dri.flash.notice.metadata_updated')
           else
             flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
             raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
             return
           end
        end
      end
    else
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
    end

    redirect_to :controller => "catalog", :action => "show", :id => params[:id]
  end

  # Ingests metadata from an XML file to create a new digital object.
  #
  #
  def create

    if params.has_key?(:metadata_file) && params[:metadata_file] != nil
      if is_valid_dc?

        if params.has_key?(:type) && params[:type].present?
          @object = DRI::Model::DigitalObject.construct(params[:type].to_sym, params[:dri_model])
        else
          flash[:alert] = t('dri.flash.error.no_type_specified')
          raise Exceptions::BadRequest, t('dri.views.exceptions.no_type_specified')
          return
        end

        if @object.datastreams.has_key?("descMetadata")
          @object.datastreams["descMetadata"].ng_xml = @tmp_xml
        else
          ds = @object.load_from_xml(@tmp_xml)
          @object.add_datastream ds, :dsid => 'descMetadata'
        end

        if params.has_key?(:governing_collection) && !params[:governing_collection].blank?
          begin
            @object.governing_collection = Collection.find(params[:governing_collection])
          rescue ActiveFedora::ObjectNotFoundError => e
            raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_collection')
            return
          end
        end

        if @object.valid?
          begin
            raise Exceptions::InternalError unless @object.save
          rescue RuntimeError => e
            logger.error "Could not save object: #{e.message}"
            raise Exceptions::InternalError
          end

          flash[:notice] = t('dri.flash.notice.digital_object_ingested')
        else
          flash[:alert] = t('dri.flash.alert.invalid_object', :error => @object.errors.full_messages.inspect)
          raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
          return
        end

        respond_to do |format|
          format.html {redirect_to :controller => "catalog", :action => "show", :id => @object.id}
          format.json  { 
            response = { :pid => @object.id }
            render :json => response, :location => catalog_url(@object), :status => :created 
          }
        end
      
        return
      else
        raise Exceptions::BadRequest, t('dri.views.exceptions.invalid_metadata')
        return
      end
    else
      flash[:notice] = t('dri.flash.notice.specify_valid_file')
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
        flash[:alert] = t('dri.flash.alert.invalid_xml', :error => e)
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
          flash[:notice] = t('dri.flash.notice.no_xml_schema')
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
            flash[:error] = t('dri.flash.error.validation_errors', :error => "<br/>".html_safe+validate_errors.join("<br/>").html_safe)
          end
        end
      else
        flash[:notice] = t('dri.flash.notice.schema_validation_error')
      end
   else
      flash[:notice] = t('dri.flash.notice.specify_xml_file')
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
