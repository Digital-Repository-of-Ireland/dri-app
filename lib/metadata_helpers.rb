require 'checksum'
require 'metadata_validator'

module MetadataHelpers

  def self.set_metadata_datastream(object, xml)
    object.update_metadata xml
  end
    
  def self.checksum_metadata(object)
    if object.datastreams.keys.include?("descMetadata")
      xml = object.datastreams["descMetadata"].content
      object.metadata_md5 = Checksum.md5_string(xml)
    end
  end

  def self.load_xml(upload)
    if MIME::Types.type_for(upload.original_filename).first.content_type.eql? 'application/xml'
      tmp = upload.tempfile

      begin
        xml = Nokogiri::XML(tmp.read) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
      rescue Nokogiri::XML::SyntaxError => e
        raise Exceptions::InvalidXML, e
        return
      end

      standard = get_metadata_class_from_xml(xml)
      result, @msg = MetadataValidator.valid?(xml, standard)

      unless result
        raise Exceptions::ValidationErrors, @msg
        return
      end

      return xml
    end

  end

  def self.get_metadata_class_from_xml xml_text
    result = nil
    xml = nil

    if (xml_text.is_a? Nokogiri::XML::Document)
      xml = xml_text
    else
      xml = Nokogiri::XML xml_text
    end

    namespace = xml.namespaces
    root_name = xml.root.name

    if namespace.has_value?("http://purl.org/dc/elements/1.1/")
     result = "DRI::Metadata::QualifiedDublinCore"
    elsif namespace.has_value?("http://www.loc.gov/mods/v3")
      # Assign correct class, based on whether the object is a collection
      result = (!xml.xpath("/mods:mods/mods:typeOfResource[@collection='yes']").empty?) ? "DRI::Metadata::ModsCollection" : "DRI::Metadata::Mods"
    elsif ((xml.internal_subset != nil && xml.internal_subset.name == 'ead') || namespace.has_value?("urn:isbn:1-931666-22-9"))
      result = "DRI::Metadata::EncodedArchivalDescription"
    elsif ['c', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'c10', 'c11', 'c12'].include? root_name
      result = "DRI::Metadata::EncodedArchivalDescriptionComponent"
    elsif namespace.has_value?("http://www.loc.gov/MARC21/slim")
      result = "DRI::Metadata::Marc"
    end

    return result
  end

  def self.get_metadata_standard_from_xml xml_text
    metadata_class = get_metadata_class_from_xml xml_text

    case metadata_class
    when "DRI::Metadata::QualifiedDublinCore"
      :qdc
    when "DRI::Metadata::ModsCollection"
      :mods_collection  
    when "DRI::Metadata::Mods"
      :mods_record
    when "DRI::Metadata::EncodedArchivalDescription"
      :ead_collection
    when "DRI::Metadata::EncodedArchivalDescriptionComponent"
      :ead_component
    when "DRI::Metadata::Marc"
      :marc
    end
  end

end
