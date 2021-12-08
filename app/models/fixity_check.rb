# frozen_string_literal: true
class FixityCheck < ActiveRecord::Base
  scope :failed, -> { where(verified: false) }

  belongs_to :fixity_report

  def header_specification
    {
      "version" => "3.0",
      "xmlns:premis" => "http://www.loc.gov/premis/v3",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => %(
        http://www.loc.gov/premis/v3
        http://www.loc.gov/standards/premis/v3/premis-v3-0.xsd
      ).gsub(/\s+/, " ")
    }
  end

  def to_premis
    xml = ::Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("premis:event", header_specification) do
      premis_event_identifier(xml)
      xml.tag!("premis:eventType", "fixity check")
      xml.tag!("premis:eventDateTime", created_at.iso8601)
      premis_event_outcome(xml)
      premis_linking_agent(xml)
      premis_linking_object(xml)
    end
  end

  def premis_event_identifier(xml)
    xml.tag!("premis:eventIdentifier") do
      xml.tag!("premis:eventIdentifierType", "local")
      xml.tag!("premis:eventIdentifierValue", object_id + ':' + id.to_s)
    end
  end

  def premis_event_outcome(xml)
    xml.tag!("premis:eventOutcomeInformation") do
      xml.tag!("premis:eventOutcome", verified ? 'pass' : 'fail')
      if result
        xml.tag!("premis:eventOutcomeDetail") do
          xml.tag!("premis:eventOutcomeDetailNote", xml.cdata!(result))
        end
      end
    end
  end

  def premis_linking_agent(xml)
    xml.tag!("premis:linkingAgentIdentifier") do
      xml.tag!("premis:linkingAgentIdentifierType", "preservation system")
      xml.tag!("premis:linkingAgentIdentifierValue", "moab-versioning v" + moab_gem_version)
    end
  end

  def premis_linking_object(xml)
    xml.tag!("premis:linkingObjectIdentifier") do
      xml.tag!("premis:linkingObjectIdentifierType", "local")
      xml.tag!("premis:linkingObjectIdentifierValue", object_id)
    end
  end

  def moab_gem_version
    Gem.loaded_specs["moab-versioning"].version.to_s
  end
end
