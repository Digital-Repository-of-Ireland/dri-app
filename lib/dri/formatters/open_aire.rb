# frozen_string_literal: true
class DRI::Formatters::OpenAire < OAI::Provider::Metadata::Format
  attr_reader :controller

  def initialize
    @prefix = "oai_openaire"
    @schema = "https://www.openaire.eu/schema/repo-lit/4.0/openaire.xsd"
    @namespace = "http://namespace.openaire.eu/schema/oaire/"
  end

  def header_specification
  end

  def resource_header
    {
      'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
      'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
      'xmlns:datacite' => "http://datacite.org/schema/kernel-4",
      'xmlns:vc' => "http://www.w3.org/2007/XMLSchema-versioning",
      'xmlns:oaire' => "http://namespace.openaire.eu/schema/oaire/",
      'xsi:schemaLocation' => "http://namespace.openaire.eu/schema/oaire/ https://www.openaire.eu/schema/repo-lit/4.0/openaire.xsd"
    }
  end

  def encode(model, record)
    @controller = model.controller
    return "" unless valid?(record)
   
    xml = Builder::XmlMarkup.new
    xml.tag!("resource", resource_header) do
      doi = DataciteDoi.find_by(object_id: record.id)
      xml.tag!('datacite:identifier', { identifierType: 'DOI' }, doi.doi) if doi
      
      xml.tag!('datacite:alternateIdentifiers', {}) do
        xml.tag!('datacite:alternateIdentifier', { identifierType: 'URL' }, "https://repository.dri.ie/catalog/#{record.id}")
      end

      xml.tag!("datacite:creators", {}) do
        record['creator_tesim'].each do |c|
          xml.tag!("datacite:creator", {}) do 
            xml.tag!("datacite:creatorName", c)
          end
        end
      end

      xml.tag!("datacite:titles", {}) do
        record['title_tesim'].each do |title|
          xml.tag!("datacite:title", title)
        end
      end

      record['description_tesim'].each do |description|
        xml.tag!("dc:description", description)
      end

      record['rights_tesim'].each do |rights|
        xml.tag!("dc:description", "Rights: #{rights}")
      end
 
      if (record.copyright.present? && record.copyright&.url.present?)
        copyright = record.copyright.url
        xml.tag!("dc:description", "#{record.copyright.name} #{record.copyright.url}")
      end

      xml.tag!("datacite:contributors") do
        xml.tag!("datacite:contributor", { "contributorType" => "RightsHolder"}) do
          xml.tag!("datacite:contributorName", {}, record.depositing_institute.try(:name))
        end
      end

      xml.tag!("datacite:dates", {}) do
        published_date = if record.key?('published_date_tesim') && record['published_date_tesim'].present?
                           parsed = DRI::Metadata::Transformations.date_range(record['published_date_tesim'].first)
                           parsed.key?("start") ? parsed['start'] : parse_published_at(record)
                         else
                           parse_published_at(record)
                         end
        xml.tag!("datacite:date", { dateType: "Issued" }, published_date)
      end

      case record.visibility
        when "public"
          xml.tag!("datacite:rights", { "rightsURI" => "http://purl.org/coar/access_right/c_abf2" }, "open access")
        when "restricted"
          xml.tag!("datacite:rights", { "rightsURI" => "http://purl.org/coar/access_right/c_14cb" }, "metadata only access")
        when "logged-in"
          xml.tag!("datacite:rights", { "rightsURI" => "http://purl.org/coar/access_right/c_16ec" }, "restricted access")
        end

      if record.licence
        if !record.licence&.url.blank?
          xml.tag!("oaire:licenseCondition", { "uri" => record.licence.url }, record.licence.name)
        else
          xml.tag!("oaire:licenseCondition", { "uri" => "https://repository.dri.ie/catalog/#{record.id}"}, record.licence.name)
        end
      end

      if record['subject_tesim'].present?
        xml.tag!("datacite:subjects") do
          record['subject_tesim'].each do |subject|
            xml.tag!("datacite:subject", {}, subject)
          end
        end
      end
    
      type = record.object_type.first.downcase

      if record.text? || type == "text"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "literature", "uri" => "http://purl.org/coar/resource_type/c_18cf" }, "text")
      elsif record.image? || type == "image"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_c513" }, "image")
      elsif record.video? || type == "video"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_12ce" }, "video")
      elsif record.audio? || type == "sound"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_18cc" }, "sound")
      elsif record.threeD? || type == "3d"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_e9a0" }, "interactive resource")
      elsif record.interactive_resource? || type == "interactiveresource"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_e9a0" }, "interactive resource")
      elsif type == "software"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "software", "uri" => "http://purl.org/coar/resource_type/c_5ce6" }, "software")
      elsif type == "dataset"
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "dataset", "uri" => "http://purl.org/coar/resource_type/c_1843" }, "other")
      else
        xml.tag!("oaire:resourceType", { "resourceTypeGeneral" => "other research product", "uri" => "http://purl.org/coar/resource_type/c_1843" }, "other")
      end
    end

    xml.target!
  end

  def parse_published_at(record)
    DateTime.parse(record['published_at_dttsi']).strftime('%Y-%m-%d')
  end

  def valid?(record)
    return false unless record.allow_aggregation?
    return false unless record.setspec.include?("openaire_data")
    return false unless record.published?
    return false unless record.depositing_institute.present?
    return false unless record.assets.size > 0

    true
  end
end
