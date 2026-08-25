# frozen_string_literal: true

module DRI
  module Formatters
    # OAI-PMH metadata formatter that renders a DRI record as an OpenAIRE
    # Guidelines for Literature Repositories (oaire) XML document.
    #
    # As with the Edm and Linkset formatters, this class is kept as a thin
    # orchestrator: the resource-type table, access-rights table,
    # published-date fallback logic, DOI lookup, and license-condition
    # resolution each live in their own collaborator class under
    # app/models/dri/formatters/open_aire/.
    class OpenAire < OAI::Provider::Metadata::Format
      attr_reader :controller

      def initialize
        @prefix = "oai_openaire"
        @schema = "https://www.openaire.eu/schema/repo-lit/4.0/openaire.xsd"
        @namespace = "http://namespace.openaire.eu/schema/oaire/"
      end

      def header_specification; end

      def resource_header
        {
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
          "xmlns:datacite" => "http://datacite.org/schema/kernel-4",
          "xmlns:vc" => "http://www.w3.org/2007/XMLSchema-versioning",
          "xmlns:oaire" => "http://namespace.openaire.eu/schema/oaire/",
          "xsi:schemaLocation" => "http://namespace.openaire.eu/schema/oaire/ https://www.openaire.eu/schema/repo-lit/4.0/openaire.xsd"
        }
      end

      def valid?(record)
        return false unless record.allow_aggregation?
        return false unless record.setspec.include?("openaire_data")
        return false unless record.published?
        return false unless record.depositing_institute.present?
        return false unless record.assets.size > 0

        true
      end

      def encode(model, record)
        @controller = model.controller
        return "" unless valid?(record)

        xml = Builder::XmlMarkup.new
        xml.tag!("resource", resource_header) do
          write_identifiers(xml, record)
          write_creators(xml, record)
          write_titles(xml, record)
          write_descriptions(xml, record)
          write_contributors(xml, record)
          write_dates(xml, record)
          write_access_rights(xml, record)
          write_license_condition(xml, record)
          write_subjects(xml, record)
          write_resource_type(xml, record)
        end

        xml.target!
      end

      def parse_published_at(record)
        PublishedDateResolver.parse_published_at(record)
      end

      private

      def write_identifiers(xml, record)
        doi = DoiFinder.find(record)
        xml.tag!("datacite:identifier", { identifierType: "DOI" }, doi.doi) if doi

        xml.tag!("datacite:alternateIdentifiers", {}) do
          xml.tag!(
            "datacite:alternateIdentifier",
            { identifierType: "URL" },
            "https://repository.dri.ie/catalog/#{record.id}"
          )
        end
      end

      def write_creators(xml, record)
        xml.tag!("datacite:creators", {}) do
          record["creator_tesim"].each do |creator|
            xml.tag!("datacite:creator", {}) do
              xml.tag!("datacite:creatorName", creator)
            end
          end
        end
      end

      def write_titles(xml, record)
        xml.tag!("datacite:titles", {}) do
          record["title_tesim"].each do |title|
            xml.tag!("datacite:title", title)
          end
        end
      end

      def write_descriptions(xml, record)
        record["description_tesim"].each do |description|
          xml.tag!("dc:description", description)
        end

        record["rights_tesim"].each do |rights|
          xml.tag!("dc:description", "Rights: #{rights}")
        end

        return unless record.copyright.present? && record.copyright&.url.present?

        xml.tag!("dc:description", "#{record.copyright.name} #{record.copyright.url}")
      end

      def write_contributors(xml, record)
        xml.tag!("datacite:contributors") do
          xml.tag!("datacite:contributor", { "contributorType" => "RightsHolder" }) do
            xml.tag!("datacite:contributorName", {}, record.depositing_institute.try(:name))
          end
        end
      end

      def write_dates(xml, record)
        xml.tag!("datacite:dates", {}) do
          xml.tag!("datacite:date", { dateType: "Issued" }, PublishedDateResolver.resolve(record))
        end
      end

      def write_access_rights(xml, record)
        rights = AccessRightsMapper.for(record.visibility)
        return unless rights

        xml.tag!("datacite:rights", { "rightsURI" => rights[:uri] }, rights[:label])
      end

      def write_license_condition(xml, record)
        license = LicenseConditionBuilder.for(record)
        return unless license

        xml.tag!("oaire:licenseCondition", { "uri" => license[:uri] }, license[:label])
      end

      def write_subjects(xml, record)
        return unless record["subject_tesim"].present?

        xml.tag!("datacite:subjects") do
          record["subject_tesim"].each do |subject|
            xml.tag!("datacite:subject", {}, subject)
          end
        end
      end

      def write_resource_type(xml, record)
        resource_type = ResourceTypeMapper.for(record)

        xml.tag!(
          "oaire:resourceType",
          { "resourceTypeGeneral" => resource_type[:resource_type_general], "uri" => resource_type[:uri] },
          resource_type[:label]
        )
      end
    end
  end
end
