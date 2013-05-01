module MetadataValidator
 
  def MetadataValidator.is_valid_dc?(xml)
    result = false
    @msg = ""

    namespace = xml.namespaces

    if namespace.has_key?("xmlns:dc") &&
      namespace["xmlns:dc"].eql?("http://purl.org/dc/elements/1.1/")

      # We have to extract all the schemata from the XML Document in order to validate correctly
      schema_imports = []

      # Firstly, if the root schema has no namespace, retrieve it from xsi:noNamespaceSchemaLocation
      if (xml.root.namespace == nil)
        no_ns_schema_location = map_to_localfile(xml.root.attr("xsi:noNamespaceSchemaLocation"))
        schema_imports = ["<xs:include schemaLocation=\""+no_ns_schema_location+"\"/>\n"]
      end

      # Then, find all elments that have the "xsi:schemaLocation" attribute and retrieve their namespace and schemaLocation
      xml.xpath("//*[@xsi:schemaLocation]").each do |node|
        schemata_by_ns = Hash[node.attr("xsi:schemaLocation").scan(/(\S+)\s+(\S+)/)]
        schemata_by_ns.each do |ns,loc|
          loc = map_to_localfile(loc)
          schema_imports = schema_imports | ["<xs:import namespace=\""+ns+"\" schemaLocation=\""+loc+"\"/>\n"]
        end
      end

      if (schema_imports.size != 0)
        # Create a schema that imports and includes the schema used in the XML
        all_schemata = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n" +
                       "<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" elementFormDefault=\"qualified\">\n" +
                       schema_imports.join("") + "</xs:schema>"

        # When parsing the schema, the local directory needs to point to the schema folder
        # as a work around to the problem Nokogiri has with parsing relative path imports.
        xsd = Dir.chdir(Rails.root.join('config').join('schemas')) do |path|
          Nokogiri::XML::Schema(all_schemata)
        end

        validate_errors = xsd.validate(xml)
        if validate_errors == nil || validate_errors.size == 0
          result = true
        else
          @msg = validate_errors.join("<br/>").html_safe
        end
      end
   end
  
   return result, @msg
  end          

  private

    # Maps a URI to a local filename if the file is found in config/schemas. Otherwise returns the original URI.
    #
    def MetadataValidator.map_to_localfile(uri)
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
