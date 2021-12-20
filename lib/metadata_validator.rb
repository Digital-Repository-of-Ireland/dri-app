# frozen_string_literal: true
module MetadataValidator
  MODS_NS_PREFIX = 'xmlns:mods'
  MODS_NS_URI = 'http://www.loc.gov/mods/v3'
  EAD_NS_PREFIX = 'xmlns:ead'
  EAD_NS_URI = 'urn:isbn:1-931666-22-9'
  DC_NS_PREFIX = 'xmlns:dc'
  DC_NS_URI = 'http://purl.org/dc/elements/1.1/'
  MARC_NS_PREFIX = 'xmlns:marc'
  MARC_NS_URI = 'http://www.loc.gov/MARC21/slim'

  # Performs XML validation
  # @param[Nokogiri::XML::Document] xml the XMl file to validate
  # @param[String] standard the metadata class associated with the XML
  # @return [Boolean] true if valid; false and error messages otherwise
  def self.valid?(xml, standard)
    case standard
    when 'DRI::Metadata::QualifiedDublinCore'
      schema_valid?(xml, DC_NS_PREFIX, DC_NS_URI)
    when 'DRI::Metadata::EncodedArchivalDescription'
      valid_ead?(xml)
    when 'DRI::Metadata::Mods'
      schema_valid?(xml, MODS_NS_PREFIX, MODS_NS_URI)
    # Add Marc validation
    when 'DRI::Metadata::Marc'
      schema_valid?(xml, MARC_NS_PREFIX, MARC_NS_URI)
    else
      [true, '']
    end
  end

  # Validate an XML file against all the XSD files it uses
  # @param[Nokogiri::XML::Document] xml the XML to validate
  # @param[String] ns_prefix the namespace prefix
  # @param[String] ns_uri the namespace URI declaration
  # @return [Boolean] true if valid; false and error messages otherwise
  def self.schema_valid?(xml, ns_prefix, ns_uri)
    namespace = xml.namespaces

    # Adapted to deal with XML using the default namespace xmlns="ns-uri"
    return false, '' unless namespace_prefix_or_uri?(namespace, ns_prefix, ns_uri)

    # We have to extract all the schemata from the XML Document in order to validate correctly
    # Firstly, if the root schema has no namespace prefix AND no default namespace, retrieve it from xsi:noNamespaceSchemaLocation
    schema_imports = no_namespace_schema_location(xml, namespace)
    # Then, find all elements that have the "xsi:schemaLocation" attribute and retrieve their namespace and schemaLocation
    # No xsi:schemaLocation
    return false, I18n.t('dri.flash.error.schema_location_missing') if schema_location_missing?(namespace, xml)

    xml.xpath('//*[@xsi:schemaLocation]').each do |node|
      schema_location = node.attr('xsi:schemaLocation')
      schemata_by_ns = Hash[schema_location.scan(/(\S+)\s+(\S+)/)]

      return false, "#{I18n.t('dri.flash.error.schema_location_parse')}: #{schema_location}" if schemata_by_ns.empty?
      schema_imports |= schema_imports_local(schemata_by_ns)
    end
    return [false, ''] if schema_imports.empty?

    # When parsing the schema, the local directory needs to point to the schema folder
    # as a work around to the problem Nokogiri has with parsing relative path imports.
    validate_errors = schema_paths_relative_to_full(schema_imports).validate(xml)
    validate_errors.blank? ? [true, ''] : [false, validate_errors.join('<br/>').html_safe]
  end

  # Checks whether an XML file uses DTD
  # @param [Nokogiri::XML::Document] xml the XML file
  # @param [String] dtd_name the name of the DTD
  # @return [Boolean] true if DTD declaration present; false otherwise
  def self.uses_dtd?(xml, dtd_name)
    xml.internal_subset && xml.internal_subset.name == dtd_name ? true : false
  end

  # Performs EAD XML validation
  # @param [Nokogiri::XML::Document] xml the XML file to validate
  # @return [Boolean] true if valid; false and error messages otherwise
  def self.valid_ead?(xml)
    uses_dtd?(xml, 'ead') ? dtd_valid?(xml, 'ead') : schema_valid?(xml, EAD_NS_PREFIX, EAD_NS_URI)
  end

  # Validates an XML file against DTD
  # @param [Nokogiri::XML::Document] xml the XML file to validate
  # @param [String] dtd_name the name of the DTD
  # @return [Boolean] true if valid; false and error messages array otherwise
  def self.dtd_valid?(xml, dtd_name)
    return false, 'The document does not include a DTD declaration.' unless uses_dtd?(xml, dtd_name)

    # Loading External DTD in Nokogiri does not work: https://github.com/sparklemotion/nokogiri/issues/440#issuecomment-3031164
    # Workaround to load the local instance of the DTD under config/schemas (*.dtd) for use in validation
    new_xml = Dir.chdir(Rails.root.join('config').join('schemas')) do |path|
      # Replace original DTD reference with a reference to the local DTD
      xml.to_xml.gsub(/<!DOCTYPE.*?>/, "<!DOCTYPE #{dtd_name} SYSTEM \"#{path}/#{dtd_name}.dtd\" >")
    end
    # Tell Nokogiri to load DTD (which is not active by default)
    options = Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::DTDLOAD
    # No url and encoding parameters needed
    doc = Nokogiri::XML::Document.parse(new_xml, nil, nil, options)

    # Validate against the DTD, if it has one
    validate_errors = doc.external_subset.nil? ? ["Could not load document DTD (#{dtd_name})"] : doc.external_subset.validate(doc)
    return [true, ''] if validate_errors.nil? || validate_errors.size.zero?

    [false, validate_errors.join('<br/>').html_safe]
  end

  def self.schema_paths_relative_to_full(schema_imports)
    Dir.chdir(Rails.root.join('config').join('schemas')) do |_path|
      Nokogiri::XML::Schema(all_schemata(schema_imports))
    end
  end

  # Create a schema that imports and includes the schema used in the XML
  def self.all_schemata(schema_imports)
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n \
    <xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" elementFormDefault=\"qualified\">\n" +
      schema_imports.join('') + '</xs:schema>'
  end

  def self.schema_imports_local(schemata_by_ns)
    schema_imports = []
    schemata_by_ns.each do |ns, loc|
      loc = map_to_localfile(loc)
      schema_imports |= ["<xs:import namespace=\"" + ns + "\" schemaLocation=\"" + loc + "\"/>\n"]
    end
    schema_imports
  end

  # Maps a URI to a local filename if the file is found in config/schemas. Otherwise returns the original URI.
  #
  def self.map_to_localfile(uri)
    return nil unless uri

    filename = URI.parse(uri).path[%r{[^/]+\z}]
    file = Rails.root.join('config').join('schemas', filename)

    Pathname.new(file).exist? ? filename : uri
  end

  def self.namespace_prefix_or_uri?(namespace, ns_prefix, ns_uri)
    (namespace.key?(ns_prefix) || namespace.key?('xmlns')) && (namespace[ns_prefix] == ns_uri || namespace['xmlns'] == ns_uri)
  end

  def self.schema_location_missing?(namespace, xml)
    !namespace.key?('xmlns:xsi') || xml.xpath('//*[@xsi:schemaLocation]').empty?
  end

  def self.no_namespace_schema_location(xml, namespace)
    return [] unless xml.root.namespace.nil? && !namespace.key?('xmlns')

    no_ns_schema_location = map_to_localfile(xml.root.attr('xsi:noNamespaceSchemaLocation'))
    no_ns_schema_location.present? ? ["<xs:include schemaLocation=\"" + no_ns_schema_location + "\"/>\n"] : []
  end
end
