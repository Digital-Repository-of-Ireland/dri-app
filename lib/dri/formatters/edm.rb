# frozen_string_literal: true


class DRI::Formatters::EDM < OAI::Provider::Metadata::Format
  def initialize
    @prefix = "oai_edm"
    @schema = "https://repository.dri.ie/oai_edm/oai_edm.xsd"
    @namespace = "https://repository.dri.ie/oai_edm/"
    @element_namespace = "edm"
  end

  # TODO: names are split by lang in names_ fields, how to handle this?
  # TODO: should we assume other fields not split are therefore English?
  ProvidedCHOPREFIXES = {
    dc: {
      title_eng: 'title_eng_tesim',
      title_gle: 'title_gle_tesim',
      description_eng: 'description_eng_tesim',
      description_gle: 'description_gle_tesim',
      creator: 'creator_tesim',
      publisher: 'publisher_tesim',
      subject_eng: 'subject_eng_tesim',
      subject_gle: 'subject_gle_tesim',
      type: 'type_tesim',
      language: 'language_tesim',
      format: 'file_type_tesim',
      rights_eng: 'rights_eng_tesim',
      rights_gle: 'rights_gle_tesim',
      source_eng: 'source_eng_tesim',
      source_gle: 'source_gle_tesim',
      coverage_eng: 'coverage_eng_tesim',
      coverage_gle: 'coverage_gle_tesim',
      date: 'date_tesim',
      created: 'creation_date_tesim'
    },
    dcterms: {
      isPartOf: "collection_id_tesim",
      #spatial_eng: "geographical_coverage_eng_tesim",
      #spatial_gle: "geographical_coverage_gle_tesim",
      spatial: "geographical_coverage_tesim",
      #temporal_eng: "temporal_coverage_eng_tesim",
      #temporal_gle: "temporal_coverage_gle_tesim",
      temporal: "temporal_coverage_tesim",
      license: lambda do |record|
        licence = record.licence
        licence.present? ? [ licence.url || licence.name ] : [nil]
      end
    },
    edm: {
      type: "type_tesim"
    },
  }.freeze


  def header_specification
    {
      "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
      "xmlns:dcterms" => "http://purl.org/dc/terms/",
      "xmlns:edm" => "http://www.europeana.eu/schemas/edm/",
      "xmlns:oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/",
      "xmlns:oai_edm" =>  "https://repository.dri.ie/oai_edm/",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:ore" => "http://www.openarchives.org/ore/terms/",
      "xmlns:skos" => "http://www.w3.org/2004/02/skos/core#",
      "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "xmlns:owl" => "http://www.w3.org/2002/07/owl#",
      "xmlns:oai" => "http://www.openarchives.org/OAI/2.0/",
      "xmlns:rdaGr2" => "http://rdvocab.info/ElementsGr2/",
      "xmlns:foaf" => "http://xmlns.com/foaf/0.1/",
      "xmlns:wgs84_pos" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
      "xsi:schemaLocation" => %(
        https://repository.dri.ie/oai_edm/
        https://repository.dri.ie/oai_edm/oai_edm.xsd
      ).gsub(/\s+/, " "),
    }
  end

  def encode(_model, record)

    # We are not going to aggregate items with no assets
    if record.assets.size < 1
      return ""
    end
    # We are not going to aggregate restricted assets to Europeana
    if not record.public_read?
        return ""
    end

    contextual_classes = []

    xml = Builder::XmlMarkup.new

    xml.tag!("rdf:RDF", header_specification) do
      xml.tag!("edm:ProvidedCHO", {"rdf:about" => "##{record.id}"}) do 
        ProvidedCHOPREFIXES.each do |pref, fields|
          fields.each do |k, v|
            values = if v.class == Proc
                       v.call(record)
                     else
                       value_for(v, record.to_h, {})
                     end

            values.each do |value|
              if k.match(/(^.*)_(eng|gle)$/)
                lang = $2
                kl = $1
              else
                kl = k
                lang = nil
              end

              if k.match(/^(temporal|spatial|created|date|coverage)$/) 
                # check for dcmi
                dcmi_components = dcmi_parse(value)
                if is_valid_dcmi?($1, dcmi_components)
                  contextual_classes.push(dcmi_components)
                  xml.tag! "#{pref}:#{kl}", {"rdf:resource" => "##{dcmi_components['name']}"}
                else
                  xml.tag! "#{pref}:#{kl}", value unless value.nil?
                end
              elsif lang.nil? || lang.empty? || lang.length == 0
                xml.tag! "#{pref}:#{kl}", value unless value.nil?
              else 
                xml.tag! "#{pref}:#{kl}", {"xml:lang" => lang}, value unless value.nil?
              end

            end
          end
        end
      end

      # If geojson field exists, make it into a contextual class
      # Maybe not as linked data urls don't appear in the geojson
      #record['geojson_ssim'].each do |geojson|
      #  place = JSON.parse(geojson)
      #  if place['geometry']['type'] == "Point"
      #  end
      #end

      # Create contextual classes
      contextual_classes.each do |cclass|
        if cclass.keys.include?("north") && cclass.keys.include?("east")
          xml.tag! "edm:Place", {"rdf:about" => "##{cclass['name']}"} do
            xml.tag! "skos:preflabel", cclass['name']
            xml.tag! "wgs84_pos:lat", cclass['north']
            xml.tag! "wgs84_pos:long", cclass['east']
          end
        elsif cclass.keys.include?("start") && cclass.keys.include?("end")
          xml.tag! "edm:TimeSpan", {"rdf:about" => "##{cclass['name']}"} do
            xml.tag! "skos:preflabel", cclass['name']
            xml.tag! "edm:begin", cclass['start']
            xml.tag! "edm:end", cclass['end']
          end
        end
      end

      if (record.licence.name == "All Rights Reserved")
        licence = "http://www.europeana.eu/rights/rr-f/"
      elsif (record.licence.name == "Orphan Work")
        licence = "http://www.europeana.eu/rights/unknown/"
      elsif (record.licence.name == "Public Domain")
        licence = "http://creativecommons.org/publicdomain/mark/1.0/"
      else
        licence = record.licence.url
      end

      xml.tag! "cc:Licence", {"rdf:about" => licence} do
        xml.tag! "odrl:inheritFrom", {"rdf:resource" => licence}
      end

      # TODO: should check if image, and get image for edm:object if available
      assets = record.assets(with_preservation: false, ordered: true)

      assets.each do |file|
        url = Rails.application.routes.url_helpers.file_download_url(record.id, file.id, type: 'surrogate')
        xml.tag!("edm:WebResource", {"rdf:about" => url}) do
          xml.tag!("edm:rights", {"rdf:resource" => licence})
        end
      end


      mainfile = assets.shift
      if mainfile.present?
        imageUrl = Rails.application.routes.url_helpers.file_download_url(record.id, mainfile.id, type: 'surrogate')
      end

      # Create the ore:Aggregation element
      xml.tag!("ore:Aggregation", {"rdf:about" => Rails.application.routes.url_helpers.catalog_url(record.id)}) do
        xml.tag!("edm:aggregatedCHO", {"rdf:resource" => "##{record.id}"})
        xml.tag!("edm:dataProvider", record.depositing_institute.try(:name))
        xml.tag!("edm:provider", "Digital Repository of Ireland")
        xml.tag!("edm:rights", {"rdf:resource" => licence})
        xml.tag!("edm:isShownBy", {"rdf:resource" => imageUrl})
        xml.tag!("edm:isShownAt", {"rdf:resource" => Rails.application.routes.url_helpers.catalog_url(record.id)})
        assets.each do |file|
          url = Rails.application.routes.url_helpers.file_download_url(record.id, file.id, type: 'surrogate')
          xml.tag!("edm:hasView", {"rdf:resource" => url})
        end
        xml.tag!("edm:object", {"rdf:resource" => imageUrl})
      end

    end

    # Create the edm:place elements
    #xml.tag!("edm:Place", {"rdf:about" => "##{dcmi_components['name']}"}) do
    #  xml.tag!("skos:prefLabel", {"xml:lang" => lang}, dcmi_components['name'])
    #end


    xml.target!
  end

  def value_for(field, record, _map)
    Array(field).map do |f|
      record[f] || []
    end.flatten.compact
  end

  def dcmi_parse(value = nil)
    dcmi_components = {}

    value.split(/\s*;\s*/).each do |component|
      (k, v) = component.split(/\s*=\s*/)
      if v.present?
        dcmi_components[k.downcase] = v.strip
      end
    end

    dcmi_components
  end

  def is_valid_dcmi?(field, dcmi)
    return false unless dcmi['name'].present?

    case field
    when "spatial" || "coverage"
      return true if dcmi['east'].present? && dcmi['north'].present?
    else
      return true if dcmi['start'].present? && dcmi['end'].present?
    end
    return false
  end

end
