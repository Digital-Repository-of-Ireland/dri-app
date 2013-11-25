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

      result, @msg = MetadataValidator.is_valid_dc?(xml)

      unless result
        raise Exceptions::ValidationErrors, @msg
        return
      end

      return xml
    end
  end

end