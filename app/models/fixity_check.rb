# frozen_string_literal: true
class FixityCheck < ActiveRecord::Base
  scope :failed, -> { where(verified: false) }

  belongs_to :fixity_report

  def to_premis
    xml = ::Builder::XmlMarkup.new
    xml.tag!("premis:event") do
      DRI::Premis.event_identifier(xml, 'local', object_id + ':' + id.to_s)
      xml.tag!("premis:eventType", "fixity check")
      xml.tag!("premis:eventDateTime", created_at.iso8601)

      outcome = verified ? 'pass' : 'fail'
      DRI::Premis.event_outcome(xml, outcome, result)
      premis_event_linking_agent_identifier(xml)
      DRI::Premis.linking_object(xml, 'local', object_id)
    end
  end

  def premis_event_linking_agent_identifier(xml)
    DRI::Premis.linking_agent(xml, 'preservation_system', "moab-versioning v" + moab_gem_version) do |premis_xml|
      premis_xml.tag!("premis:linkingAgentRole",
              {
                "authority" => "eventRelatedAgentRole",
                "authorityURI" => "http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole",
                "valueURI" => "http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/exe"
              },
             "executing program")
    end
  end

  def moab_gem_version
    Gem.loaded_specs["moab-versioning"].version.to_s
  end
end
