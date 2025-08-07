# frozen_string_literal: true
class DRI::Formatters::OpenAire < OAI::Provider::Metadata::Format
  attr_reader :controller

  DATES = { 
    'creation_date_tesim' => 'Created',
    'published_date_tesim' => 'Issued',
    'date_tesim' => "Other"
  }.freeze

  def initialize
    @prefix = "oai_datacite"
    @schema = "http://schema.datacite.org/meta/kernel-4/metadata.xsd"
    @namespace = "http://datacite.org/schema/kernel-4"
  end

  def header_specification
    {
      'xmlns' => "http://schema.datacite.org/oai/oai-1.1/",
      'xsi:schemaLocation'=> %(
        http://schema.datacite.org/oai/oai-1.1/ 
        http://schema.datacite.org/oai/oai-1.1/oai.xsd
      ).gsub(/\s+/, " ")
    }
  end

  def resource_header
    {
      'xmlns' => 'http://datacite.org/schema/kernel-4',
      'xsi:schemaLocation'=> %(
        http://datacite.org/schema/kernel-4
        http://schema.datacite.org/meta/kernel-4/metadata.xsd
      )
    }
  end

  def encode(model, record)
    @controller = model.controller
  
    return "" unless valid?(record)

    xml = Builder::XmlMarkup.new
    xml.tag!("#{prefix}", header_specification) do
      xml.tag!("schemaVersion", {}, 4)
      xml.tag!("datacentreSymbol", {}, "BL.DRI")

      xml.tag!("payload") do
        xml.tag!("resource", resource_header) do
          doi = DataciteDoi.find_by(object_id: record.id)
          resource = Nokogiri::XML(doi.to_xml).children[0].children.to_xml
          xml << resource

          xml.tag!("descriptions", {}) do
            record['description_tesim'].each do |description|
              xml.tag!("description", { "descriptionType" => "Abstract"}, description)
            end
          end

          xml.tag!("contributors") do
            xml.tag!("contributor", { "contributorType" => "RightsHolder"}) do
              xml.tag!("contributorName", {}, record.depositing_institute.try(:name))
            end
          end

          xml.tag!("dates", {}) do
            parse_dates(record, xml)
          end

          xml.tag!("rightsList") do
            record['rights_tesim'].each do |rights|
              xml.tag!("rights", rights)
            end

            case record.visibility
            when "public"
              xml.tag!("rights", { "rightsURI" => "info:eu-repo/semantics/openAccess" })
            when "restricted"
              xml.tag!("rights", { "rightsURI" => "info:eu-repo/semantics/restrictedAccess" })
            end

            if (record.copyright.present? && record.copyright&.url.present?)
              copyright = record.copyright.url
              xml.tag!("rights", { "rightsURI" => record.copyright.url }, record.copyright.name)
            end

            if record.licence
              if !record.licence&.url.blank?
                xml.tag!("rights", { "rightsURI" => record.licence.url }, record.licence.name)
              else
                xml.tag!("rights", {}, record.licence.name)
              end
            end

            if record['subject_tesim'].present?
              xml.tag!("subjects") do
                record['subject_tesim'].each do |subject|
                  xml.tag!("subject", {}, subject)
                end
              end
            end
          end
        end
      end
    end

    xml.target!
  end

  def parse_dates(record, xml)
    DATES.each do |k, date_type|
      next unless record.key?(k)

      record[k].each do |date|
        parsed = DRI::Metadata::Transformations.date_range(date)
        if parsed.key?('start') && parsed.key?('end')
          xml.tag!("date", {dateType: date_type}, "#{parsed['start']}/#{parsed['end']}")
        elsif parsed.key?('start')
          xml.tag!("date", {dateType: date_type}, "#{parsed['start']}")
        end
      end
    end
  end

  def valid?(record)
    return false unless record.allow_aggregation?
    return false unless record.setspec.include?("openaire_data")
    return false unless record.published?
    return false unless record.depositing_institute.present?

    true
  end
end
