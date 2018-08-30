class XmlDatastream
  include ActiveModel::Model

  attr_accessor :xml, :metadata_standard, :metadata_class

  def metadata_class
    @metadata_class ||= metadata_class_from_xml
  end

  def metadata_standard
    @metadata_standard ||= metadata_standard_from_xml
  end

  def load_xml(upload)
    return read_xml(upload) unless upload.respond_to?(:original_filename)

    types = MIME::Types.type_for(upload.original_filename)
    if types.blank? || types.first.content_type != 'application/xml'
      errors.add(:xml, :invalid_metadata, message: 'non-xml file uploaded')
      raise DRI::Exceptions::InvalidXML, 'non-xml file uploaded'
    end

    read_xml(upload.tempfile)
  end

  private

  def read_xml(xml_upload)
    begin
      xml_content = xml_upload.respond_to?(:read) ? xml_upload.read : xml_upload
      @xml = Nokogiri::XML(xml_content) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
    rescue Nokogiri::XML::SyntaxError => e
      errors.add(:xml, :invalid_metadata, message: e.message)
      raise DRI::Exceptions::InvalidXML, e
    end

    result, msg = MetadataValidator.valid?(@xml, metadata_class)
    unless result
      errors.add(:xml, :invalid_metadata, message: msg)
      raise DRI::Exceptions::ValidationErrors, msg
    end

    xml
  end

  def metadata_standard_from_xml
    case metadata_class
    when 'DRI::Metadata::QualifiedDublinCore'
      :qdc
    when 'DRI::Metadata::Mods'
      :mods
    when 'DRI::Metadata::EncodedArchivalDescription'
      :ead_collection
    when 'DRI::Metadata::EncodedArchivalDescriptionComponent'
      :ead_component
    when 'DRI::Metadata::Marc'
      :marc
    end
  end

  def metadata_class_from_xml
    namespace = xml.namespaces
    root_name = xml.root.name

    if namespace.value?('http://purl.org/dc/elements/1.1/')
      'DRI::Metadata::QualifiedDublinCore'
    elsif namespace.value?('http://www.loc.gov/mods/v3')
      'DRI::Metadata::Mods'
    elsif (!xml.internal_subset.nil? && xml.internal_subset.name == 'ead') || namespace.value?('urn:isbn:1-931666-22-9')
      'DRI::Metadata::EncodedArchivalDescription'
    elsif ['c', 'c01', 'c02', 'c03', 'c04', 'c05', 'c06', 'c07', 'c08', 'c09', 'c10', 'c11', 'c12'].include? root_name
      'DRI::Metadata::EncodedArchivalDescriptionComponent'
    elsif namespace.value?('http://www.loc.gov/MARC21/slim')
      'DRI::Metadata::Marc'
    end
  end
end
