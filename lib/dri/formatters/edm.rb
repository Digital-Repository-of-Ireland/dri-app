# frozen_string_literal: true

module DRI
  module Formatters
    # OAI-PMH metadata formatter that renders a DRI record as an EDM
    # (Europeana Data Model) XML document, for harvesting into Europeana.
    #
    # This class is intentionally kept as a thin orchestrator: field-mapping
    # config, DCMI parsing, asset/type selection, URL building, and
    # Transcribathon/geojson enrichment each live in their own collaborator
    # class under app/models/dri/formatters/edm/.
    class Edm < OAI::Provider::Metadata::Format
      include ActionController::UrlFor
      include Rails.application.routes.url_helpers

      delegate :riiif, :env, :request, to: :controller

      attr_reader :controller

      # Licences we deliberately do not aggregate to Europeana.
      UNSUPPORTED_LICENCES = [
        "ODC-ODbL", "ODC-BY", "ODC-PPDL", "Educational Use", "Open COVID Licence 1.1"
      ].freeze

      def initialize
        @prefix = "edm"
        @schema = "https://repository.dri.ie/edm/edm.xsd"
        @namespace = "https://repository.dri.ie/edm/"
        @element_namespace = "edm"
      end

      def header_specification
        {
          "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
          "xmlns:dcterms" => "http://purl.org/dc/terms/",
          "xmlns:edm" => "http://www.europeana.eu/schemas/edm/",
          "xmlns:oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/",
          "xmlns:ore" => "http://www.openarchives.org/ore/terms/",
          "xmlns:skos" => "http://www.w3.org/2004/02/skos/core#",
          "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          "xmlns:owl" => "http://www.w3.org/2002/07/owl#",
          "xmlns:oai" => "http://www.openarchives.org/OAI/2.0/",
          "xmlns:rdaGr2" => "http://rdvocab.info/ElementsGr2/",
          "xmlns:foaf" => "http://xmlns.com/foaf/0.1/",
          "xmlns:wgs84_pos" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
          "xmlns:ebucore" => "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
          "xmlns:doap" => "http://usefulinc.com/ns/doap#",
          "xmlns:odrl" => "http://www.w3.org/ns/odrl/2/",
          "xmlns:cc" => "http://creativecommons.org/ns#",
          "xmlns:svcs" => "http://rdfs.org/sioc/services#",
          "xmlns:sch" => "http://purl.oclc.org/dsdl/schematron"
        }
      end

      def valid?(record)
        return false unless record.published?
        return false if record.assets.size < 1
        # We are not going to aggregate restricted assets to Europeana
        return false unless record.public_read?

        true
      end

      def encode(model, record)
        @controller = model.controller

        # We are not going to aggregate items with no assets, or restricted
        # assets, to Europeana.
        return "" unless record.assets.size >= 1 && record.public_read?

        @url_builder = UrlBuilder.new(controller)

        edmtype = AssetSelector.edm_type(record["type_tesim"])
        assets = AssetSelector.clean(record.assets(with_preservation: false, ordered: false))

        aggregation = Aggregation.where(collection_id: record.root_collection_id).first
        mainfile = AssetSelector.mainfile_for_type(edmtype, assets, aggregation&.iiif_main?)
        return "" if mainfile.blank?

        imagefile = AssetSelector.mainfile_for_type("IMAGE", assets)
        thumbnail = @url_builder.thumbnail_url(record, mainfile, imagefile)

        return "" if UNSUPPORTED_LICENCES.include?(record.licence.name)

        licence = record.licence.url
        return "" unless record.copyright.present? && record.copyright&.url.present?

        copyright = record.copyright.url
        landing_page = @url_builder.doi_url(record, aggregation&.doi_from_metadata) || controller.catalog_url(record.id)

        contextual_classes = []
        transcribathon = TranscribathonEnricher.new(record)
        geojson_places = GeojsonPlaceBuilder.new(record)

        xml = Builder::XmlMarkup.new
        xml.tag!("rdf:RDF", header_specification) do
          xml.tag!("edm:ProvidedCHO", { "rdf:about" => "##{record.id}" }) do
            write_metadata_fields(xml, record, edmtype, contextual_classes)
            transcribathon.write(xml)
          end

          geojson_places.write(xml)
          write_contextual_classes(xml, contextual_classes)
          write_licence(xml, licence)
          write_copyright(xml, copyright)
          write_user_generated_dates(xml, transcribathon.dates)
          write_user_generated_places(xml, transcribathon.places)

          write_aggregation(xml, record, mainfile, assets, licence, copyright, landing_page, thumbnail)
          write_image_web_resource(xml, record, mainfile, licence, copyright) if mainfile["file_type_tesim"].include?("image")
          write_asset_web_resources(xml, record, assets, mainfile, licence, copyright)
          write_thumbnail_web_resource(xml, thumbnail, licence)
        end

        xml.target!
      end

      private

      # --- edm:ProvidedCHO metadata fields ------------------------------

      def write_metadata_fields(xml, record, edmtype, contextual_classes)
        FieldMapper.each_field do |prefix, key, source|
          if prefix == :edm && key == :type
            xml.tag! "edm:type", edmtype
            next
          end

          FieldMapper.values_for(source, record).each do |value|
            write_field(xml, prefix, key, value, contextual_classes)
          end
        end
      end

      def write_field(xml, prefix, key, value, contextual_classes)
        kl, lang = split_key(key)

        if kl.match?(/^(spatial|coverage).*$/)
          write_spatial_field(xml, prefix, kl, lang, value)
        elsif kl.match?(/^(temporal|created|issued|date|coverage).*$/)
          write_temporal_field(xml, prefix, kl, value, contextual_classes)
        elsif kl.match?(/^(subject).*$/) && @url_builder.valid_url?(value)
          xml.tag! "#{prefix}:#{kl}", { "rdf:resource" => value }
        elsif lang.blank?
          xml.tag! "#{prefix}:#{kl}", value unless value.nil?
        else
          xml.tag! "#{prefix}:#{kl}", { "xml:lang" => lang }, value unless value.nil?
        end
      end

      def split_key(key)
        key = key.to_s

        if key =~ /(^.*)_(eng|gle)$/
          [Regexp.last_match(1), Regexp.last_match(2)]
        elsif key.match?(/^(type|format|medium)$/)
          [key, "eng"]
        else
          [key, nil]
        end
      end

      def write_spatial_field(xml, prefix, kl, lang, value)
        dcmi = DcmiParser.parse(value)

        if DcmiParser.valid_point?(dcmi)
          xml.tag! "#{prefix}:#{kl}", { "rdf:resource" => "##{dcmi['name'].tr(' ', '_')}" }
        elsif @url_builder.valid_url?(value)
          host = URI(Addressable::URI.encode(value.strip)).host
          if AuthoritiesConfig[host].present?
            xml.tag! "#{prefix}:#{kl}", { "rdf:resource" => value }
          else
            xml.tag! "#{prefix}:#{kl}", value
          end
        elsif lang.present?
          xml.tag! "#{prefix}:#{kl}", { "xml:lang" => lang }, value
        else
          xml.tag! "#{prefix}:#{kl}", value
        end
      end

      def write_temporal_field(xml, prefix, kl, value, contextual_classes)
        dcmi = DcmiParser.parse(value)

        if DcmiParser.valid_period?(dcmi)
          contextual_classes.push(dcmi)
          xml.tag! "#{prefix}:#{kl}", { "rdf:resource" => "##{dcmi['name'].tr(' ', '_')}" }
        else
          v = dcmi["name"] || value
          xml.tag! "#{prefix}:#{kl}", v unless v.nil?
        end
      end

      # --- Contextual classes --------------------------------------------

      def write_contextual_classes(xml, contextual_classes)
        contextual_classes.each do |cclass|
          next unless cclass.key?("start")

          xml.tag! "edm:TimeSpan", { "rdf:about" => "##{cclass['name'].tr(' ', '_')}" } do
            xml.tag! "skos:prefLabel", cclass["name"]
            xml.tag! "edm:begin", cclass["start"]
            xml.tag! "edm:end", cclass["end"] || cclass["start"]
          end
        end
      end

      def write_user_generated_dates(xml, dates)
        dates.each do |key, value|
          xml.tag! "edm:TimeSpan", { "rdf:about" => "##{key.tr(' ', '_')}" } do
            xml.tag! "skos:prefLabel", key
            xml.tag! "edm:begin", value["start"]
            xml.tag! "edm:end", value["end"]
          end
        end
      end

      def write_user_generated_places(xml, places)
        places.each do |name, lat, long|
          xml.tag! "edm:Place", { "rdf:about" => "##{name}" } do
            xml.tag! "skos:prefLabel", { "xml:lang" => "en" }, name
            xml.tag! "wgs84_pos:lat", lat
            xml.tag! "wgs84_pos:long", long
          end
        end
      end

      # --- Rights ----------------------------------------------------------

      def write_licence(xml, licence)
        xml.tag! "cc:Licence", { "rdf:about" => licence } do
          xml.tag! "odrl:inheritFrom", { "rdf:resource" => licence }
        end
      end

      def write_copyright(xml, copyright)
        xml.tag! "cc:Copyright", { "rdf:about" => copyright } do
          xml.tag! "odrl:inheritFrom", { "rdf:resource" => copyright }
        end
      end

      # --- ore:Aggregation ---------------------------------------------

      def write_aggregation(xml, record, mainfile, assets, licence, copyright, landing_page, thumbnail)
        xml.tag!("ore:Aggregation", { "rdf:about" => controller.catalog_url(record.id) }) do
          xml.tag!("edm:aggregatedCHO", { "rdf:resource" => "##{record.id}" })
          xml.tag!("edm:dataProvider", record.depositing_institute.try(:name))
          xml.tag!("edm:provider", { "xml:lang" => "eng" }, "Digital Repository of Ireland")
          xml.tag!("edm:rights", { "rdf:resource" => licence })
          xml.tag!("edm:copyright", { "rdf:resource" => copyright })

          is_shown_by = @url_builder.file_url_for(record, mainfile)
          xml.tag!("edm:isShownBy", { "rdf:resource" => is_shown_by }) if is_shown_by
          xml.tag!("edm:isShownAt", { "rdf:resource" => landing_page })

          images = 0
          assets.each do |file|
            next if file.id == mainfile.id || !file.key?("file_type_tesim")

            if file["file_type_tesim"].include?("image")
              next if images.positive? || mainfile["file_type_tesim"].include?("image")

              images += 1
            end

            url = @url_builder.file_url_for(record, file)
            xml.tag!("edm:hasView", { "rdf:resource" => url }) if url
          end

          xml.tag!("edm:object", { "rdf:resource" => thumbnail })
        end
      end

      # --- edm:WebResource / svcs:Service -------------------------------

      def write_image_web_resource(xml, record, mainfile, licence, copyright)
        image_url = riiif.image_url("#{record.id}:#{mainfile.id}", size: "full")
        manifest_url = controller.iiif_manifest_url(record.id.to_s, format: :json)
        base_url = riiif.base_url("#{record.id}:#{mainfile.id}")

        write_iiif_web_resource(xml, image_url, base_url, manifest_url, licence, copyright)
      end

      def write_asset_web_resources(xml, record, assets, mainfile, licence, copyright)
        images = 0

        assets.each do |file|
          next unless file.key?("file_type_tesim")

          types = file["file_type_tesim"]

          if types.include?("image")
            # Only the first non-main image asset (when the main file isn't
            # itself an image) gets its own IIIF web resource + service.
            next if images.positive? || mainfile["file_type_tesim"].include?("image")

            image_url = riiif.image_url("#{record.id}:#{file.id}", size: "full")
            manifest_url = controller.iiif_manifest_url(record.id.to_s, format: :json)
            base_url = riiif.base_url("#{record.id}:#{file.id}")

            write_iiif_web_resource(xml, image_url, base_url, manifest_url, licence, copyright)
            images += 1
            next
          end

          url = @url_builder.file_url_for(record, file)
          next unless url

          xml.tag!("edm:WebResource", { "rdf:about" => url }) do
            xml.tag!("edm:rights", { "rdf:resource" => licence })
          end
        end
      end

      def write_iiif_web_resource(xml, image_url, base_url, manifest_url, licence, copyright)
        xml.tag!("edm:WebResource", { "rdf:about" => image_url }) do
          xml.tag!("edm:rights", { "rdf:resource" => licence })
          xml.tag!("edm:copyright", { "rdf:resource" => copyright })
          xml.tag!("svcs:has_service", { "rdf:resource" => base_url })
          xml.tag!("dcterms:isReferencedBy", { "rdf:resource" => manifest_url })
        end
        xml.tag!("svcs:Service", { "rdf:about" => base_url }) do
          xml.tag!("dcterms:conformsTo", { "rdf:resource" => "http://iiif.io/api/image" })
          xml.tag!("doap:implements", { "rdf:resource" => "http://iiif.io/api/image/2/level2.json" })
        end
      end

      def write_thumbnail_web_resource(xml, thumbnail, licence)
        xml.tag!("edm:WebResource", { "rdf:about" => thumbnail }) do
          xml.tag!("edm:rights", { "rdf:resource" => licence })
        end
      end
    end
  end
end
