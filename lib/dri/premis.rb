# frozen_string_literal: true
module DRI
  class Premis
    def to_premis
      xml = ::Builder::XmlMarkup.new
      xml.instruct!
      xml.tag!("premis:premis", self.class.header_specification) do
        yield(xml) if block_given?
      end
    end

    def self.header_specification
      {
        "xmlns:premis" => "http://www.loc.gov/premis/v3",
        "xmlns:xlink" => "http://www.w3.org/1999/xlink",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => %(http://www.loc.gov/premis/v3 https://www.loc.gov/standards/premis/premis.xsd).gsub(/\s+/, " "),
        "version" => "3.0"
      }
    end

    def self.event_identifier(xml, type, identifier)
      xml.tag!("premis:eventIdentifier") do
        xml.tag!("premis:eventIdentifierType", type)
        xml.tag!("premis:eventIdentifierValue", identifier)
      end
    end

    def self.event_outcome(xml, outcome, detail = nil)
      xml.tag!("premis:eventOutcomeInformation") do
        xml.tag!("premis:eventOutcome", outcome)
        if detail
          xml.tag!("premis:eventOutcomeDetail") do
            xml.tag!("premis:eventOutcomeDetailNote") { xml.cdata!(detail) }
          end
        end
      end
    end

    def self.linking_agent(xml, type, agent)
      xml.tag!("premis:linkingAgentIdentifier") do
        xml.tag!("premis:linkingAgentIdentifierType", type)
        xml.tag!("premis:linkingAgentIdentifierValue", agent)

        yield(xml) if block_given?
      end
    end

    def self.linking_object(xml, type, identifier)
      xml.tag!("premis:linkingObjectIdentifier") do
        xml.tag!("premis:linkingObjectIdentifierType", type)
        xml.tag!("premis:linkingObjectIdentifierValue", identifier)
      end
    end

    def self.object_identifier(xml, object)
      xml.tag!("premis:objectIdentifier") do
        xml.tag!("premis:objectIdentifierType", "local")
        xml.tag!("premis:objectIdentifierValue", object.alternate_id)
      end

      return if object.doi.blank?

      xml.tag!("premis:objectIdentifier") do
        xml.tag!("premis:objectIdentifierType", "DOI")
        xml.tag!("premis:objectIdentifierValue", object.doi)
      end
    end
  end
end
