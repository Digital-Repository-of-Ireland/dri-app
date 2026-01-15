# frozen_string_literal: true
class DRI::Formatters::Edm < OAI::Provider::Metadata::Format
  include ActionController::UrlFor
  include Rails.application.routes.url_helpers

  delegate :riiif, :env, :request, to: :controller

  attr_reader :controller

  def initialize
    @prefix = "edm"
    @schema = "https://repository.dri.ie/edm/edm.xsd"
    @namespace = "https://repository.dri.ie/edm/"
    @element_namespace = "edm"
  end
  # TODO: names are split by lang in names_ fields, how to handle this?
  # TODO: should we assume other fields not split are therefore English?
  ProvidedCHOPREFIXES = {
    dc: {
      title_eng: 'title_eng_tesim',
      title_gle: 'title_gle_tesim',
      title: lambda do |record|
        titles = (record['title_tesim']||[]).map(&:strip)
        titles = titles -(record['title_eng_tesim'] || []).map(&:strip)
        titles = titles - (record['title_gle_teim'] || []).map(&:strip)
        titles || []
      end,
      description_eng: 'description_eng_tesim',
      description_gle: 'description_gle_tesim',
      description: lambda do |record|
        descriptions = (record['description_tesim'] || []).map(&:strip)
        descriptions = descriptions - (record['description_eng_tesim'] || []).map(&:strip)
        descriptions = descriptions - (record['description_gle_tesim'] || []).map(&:strip)
        descriptions || []
      end,
      creator: 'creator_tesim',
      publisher: 'publisher_tesim',
      subject_eng: 'subject_eng_tesim',
      subject_gle: 'subject_gle_tesim',
      subject: lambda do |record|
        subjects = (record['subject_tesim'] || []).map(&:strip)
        subjects = subjects - (record['subject_eng_tesim'] || []).map(&:strip)
        subjects = subjects - (record['subject_gle_tesim'] || []).map(&:strip)
        subjects || []
      end,
      type: 'type_tesim',
      language: 'language_tesim',
      format: 'file_type_tesim',
      rights_eng: 'rights_eng_tesim',
      rights_gle: 'rights_gle_tesim',
      rights: lambda do |record|
        rights = (record['rights_tesim'] || []).map(&:strip)
        rights = rights - (record['rights_eng_tesim'] || []).map(&:strip)
        rights = rights - (record['rights_gle_tesim'] || []).map(&:strip)
        rights || []
      end,
      source_eng: 'source_eng_tesim',
      source_gle: 'source_gle_tesim',
      source: lambda do |record|
        sources = (record['source_tesim'] || []).map(&:strip)
        sources = sources - (record['source_eng_tesim'] || []).map(&:strip)
        sources = sources - (record['source_gle_tesim'] || []).map(&:strip)
        sources || []
       end,
      coverage_eng: 'coverage_eng_tesim',
      coverage_gle: 'coverage_gle_tesim',
      coverage: lambda do |record|
        coverages = (record['coverage_tesim'] || []).map(&:strip)
        coverages = coverages - (record['coverage_eng_tesim'] || []).map(&:strip)
        coverages = coverages - (record['coverage_gle_tesim'] || []).map(&:strip)
        coverages || []
      end,
      date: 'date_tesim',
      contributor: 'person_tesim'
    },
    dcterms: {
      created: 'creation_date_tesim',
      issued: 'published_date_tesim',
      spatial_eng: "geographical_coverage_eng_tesim",
      spatial_gle: "geographical_coverage_gle_tesim",
      spatial: lambda do |record|
        spatials = (record['geographical_coverage_tesim'] || []).map(&:strip)
        spatials = spatials - (record['geographical_coverage_eng_tesim'] || []).map(&:strip)
        spatials = spatials - (record['geographical_coverage_gle_tesim'] || []).map(&:strip)
        spatials || []
       end,
      temporal: "temporal_coverage_tesim"
    },
    edm: {
      type: "object_type_ssm"
    },
  }.freeze

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

  def encode(model, record)
    @controller = model.controller
    # We are not going to aggregate items with no assets
    if record.assets.size < 1
      return ""
    end
    # We are not going to aggregate restricted assets to Europeana
    if not record.public_read?
      return ""
    end

    # Fetch the aggregation config
    aggregation = Aggregation.where(collection_id: record.root_collection_id).first

    # Identify the type
    edmtype = self.class::edm_type(record["type_tesim"]);
    contextual_classes = []
    ug_date = {}
    ug_places = []

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
              if pref.match(/^edm$/) && k.match(/^type$/)
                xml.tag! "edm:type", edmtype
                next
              end

              values.each do |value|
                if k.match(/(^.*)_(eng|gle)$/)
                  lang = $2
                  kl = $1
                elsif k.match(/^(type|format|medium)$/)
                  kl = k
                  lang = "eng"
                else
                  kl = k
                  lang = nil
                end

                if kl.match(/^(spatial|coverage).*$/)
                  dcmi_components = dcmi_parse(value)
                    if is_valid_point?(dcmi_components)
                    xml.tag! "#{pref}:#{kl}", {"rdf:resource" => "##{dcmi_components['name'].tr(" ", "_")}"}
                  elsif valid_url?(value)
                    host = URI(Addressable::URI.encode(value.strip)).host
                    if AuthoritiesConfig[host].present?
                      xml.tag! "#{pref}:#{kl}", {"rdf:resource" => value}
                    else
                      xml.tag! "#{pref}:#{kl}", value
                    end
                  elsif lang.present?
                    xml.tag! "#{pref}:#{kl}", {"xml:lang" => lang}, value
                  else
                    xml.tag! "#{pref}:#{kl}", value
                  end
                elsif kl.match(/^(temporal|created|issued|date|coverage).*$/)
                  # If it's a dcmi period field then we can parse it
                  dcmi_components = dcmi_parse(value)
                  if is_valid_period?(dcmi_components)
                    contextual_classes.push(dcmi_components)
                    xml.tag! "#{pref}:#{kl}", {"rdf:resource" => "##{dcmi_components['name'].tr(" ", "_")}"}
                  else
                    v = dcmi_components["name"] || value
                    xml.tag! "#{pref}:#{kl}", v unless v.nil?
                  end
                elsif kl.match(/^(subject).*$/) && valid_url?(value)
                    xml.tag! "#{pref}:#{kl}",{"rdf:resource"=> value}
                elsif lang.nil? || lang.empty? || lang.length == 0
                  xml.tag! "#{pref}:#{kl}", value unless value.nil?
                else
                  xml.tag! "#{pref}:#{kl}", {"xml:lang" => lang}, value unless value.nil?
                end
              end
            end 
          end # End metadata fields in edm:ProvidedCHO

          # Add fields from Transcribathon with User provenance
          tp_story = TpStory.where(dri_id: record.id).first
          if tp_story.present?
            tp_processed_dates = []
            tp_processed_people = []
            tp_story.items.map { |i|
              if i.start_date || i.end_date
                datestring = [i.start_date, i.end_date].reject(&:blank?).join(" - ")
                next if tp_processed_dates.include? datestring
                tp_processed_dates << datestring
                xml.tag! "dc:date", {"edm:wasGeneratedBy" => "Person"}, datestring
                datehash = {}
                datehash['start'] = i.start_date ? i.start_date : i.end_date
                datehash['end'] = i.end_date ? i.end_date : i.start_date
                ug_date[datestring] = datehash
              end
            }

            tp_story.people.map { |i|
              name = [i.last_name, i.first_name].reject { |s| s == "NULL" || s.blank? }.join(", ")
              dates = [i.birth_date, i.death_date].join(" - ") unless i.birth_date.blank? && i.death_date.blank?
              desc = " (#{i.person_description})" unless i.person_description == "NULL" || i.person_description == "NULL"
              namestring = [name, dates].reject(&:blank?).join(", ") + desc
              next if tp_processed_people.include? namestring
              tp_processed_people << namestring
              xml.tag! "dc:subject",
                       {"edm:wasGeneratedBy" => "Person", "xml:lang" => "eng"},
                       namestring 
            }

            tp_story.places.map { |i|
              if i.place_name.present? && i.latitude.present? && i.longitude.present?
                tmp = [i.place_name, i.latitude, i.longitude]
                next if ug_places.include? tmp
                ug_places.push(tmp)
                xml.tag! "dcterms:spatial", {"rdf:resource" => "##{i.place_name}", "edm:wasGeneratedBy" => "Person"}
              elsif i.wikidata_id.present?
                url = Settings.transcribathon.wikidata_endpoint + i.wikidata_id.strip
                xml.tag! "dcterms:spatial", {"rdf:resource" => "##{url}", "edm:wasGeneratedBy" => "Person"}
              elsif i.place_name.present?
                xml.tag! "dcterms:spatial", {"edm:wasGeneratedBy" => "Person", "xml:lang" => "eng"}, i.place_name 
              end
            }

          end
      end

      # If geojson field exists, make it into a contextual class
      if record['geojson_ssim'].present?
        record['geojson_ssim'].each do |geojson|
          place = JSON.parse(geojson)
          if place['geometry']['type'] == "Point"
            ga = place['properties']['nameGA']
            en = place['properties']['nameEN'] || place['properties']['placename']
            tmp = place['properties']['uri'] || place['properties']['placename'] || place['geometry']['coordinates'].to_s
            about = "##{tmp.tr(" ", "")}"
            east,north = place['geometry']['coordinates']
            if north.present? && east.present?
              xml.tag! "edm:Place", {"rdf:about" => about} do
                xml.tag! "skos:prefLabel", {"xml:lang" => "ga"}, ga unless ga.blank?
                xml.tag! "skos:prefLabel", {"xml:lang" => "en"}, en unless en.blank?
                xml.tag! "wgs84_pos:lat", north
                xml.tag! "wgs84_pos:long", east
              end
            end
          end
        end
      end

      # Create other contextual classes

      contextual_classes.each do |cclass|
        if cclass.keys.include?("start")
          xml.tag! "edm:TimeSpan", {"rdf:about" => "##{cclass['name'].tr(" ", "_")}"} do
            xml.tag! "skos:prefLabel", cclass['name']
            xml.tag! "edm:begin", cclass['start']
            xml.tag! "edm:end", cclass['end'] || cclass['start']
          end
        end
      end

      if (["ODC-ODbL", "ODC-BY", "ODC-PPDL", "Educational Use", "Open COVID Licence 1.1"].include?(record.licence.name))
        return ""
      else
        licence = record.licence.url
      
        xml.tag! "cc:Licence", {"rdf:about" => licence} do
          xml.tag! "odrl:inheritFrom", {"rdf:resource" => licence}
        end
      end

      if (record.copyright.present? && record.copyright&.url.present?)
        copyright = record.copyright.url
      
        xml.tag! "cc:Copyright", {"rdf:about" => copyright} do
          xml.tag! "odrl:inheritFrom", {"rdf:resource" => copyright}
        end
      else
        return ""
      end

      # Create Contextual classes for user-generated enrichments
      ug_date.each do |key,value|
        xml.tag! "edm:TimeSpan", {"rdf:about" => "##{key.tr(" ", "_")}"} do
          xml.tag! "skos:prefLabel", key
          xml.tag! "edm:begin", value['start']
          xml.tag! "edm:end", value['end']
        end
      end

      ug_places.map { |p|
        # i.place_name, i.latitude, i.longitude
        xml.tag! "edm:Place", {"rdf:about" => "##{p[0]}"} do
          xml.tag! "skos:prefLabel", {"xml:lang" => "en"}, p[0] 
          xml.tag! "wgs84_pos:lat", p[1]
          xml.tag! "wgs84_pos:long", p[2]
        end
      }

      # Get the asset files
      assets = clean_assets(record.assets(with_preservation: false, ordered: false))
      doi_flag = aggregation.doi_from_metadata if aggregation.present?
      landing_page = doi_url(record, doi_flag) || catalog_url(record.id)

      # identify which is the main file (based on metadata type)
      # and get correct Urls
      iiif_flag = aggregation.iiif_main? if aggregation.present?
      mainfile = self.class::mainfile_for_type(edmtype, assets, iiif_flag)
      imagefile = self.class::mainfile_for_type("IMAGE", assets)
      if mainfile.present?
        thumbnail = thumbnail_url(record, edmtype, mainfile, imagefile)
      else
        return ""
      end

      # Create the ore:Aggregation element
      xml.tag!("ore:Aggregation", {"rdf:about" => catalog_url(record.id)}) do
        xml.tag!("edm:aggregatedCHO", {"rdf:resource" => "##{record.id}"})
        xml.tag!("edm:dataProvider", record.depositing_institute.try(:name))
        xml.tag!("edm:provider", {"xml:lang" => "eng"}, "Digital Repository of Ireland")
        xml.tag!("edm:rights", {"rdf:resource" => licence})
        xml.tag!("edm:copyright", {"rdf:resource" => copyright})

        if mainfile['file_type_tesim'].include? "video"
          is_shown_by   = object_file_url(record.id, mainfile.id, surrogate: 'mp4')
        elsif mainfile['file_type_tesim'].include? "audio"
          is_shown_by   = object_file_url(record.id, mainfile.id, surrogate: 'mp3')
        elsif mainfile['file_type_tesim'].include? "image"
          is_shown_by   = riiif.image_url("#{record.id}:#{mainfile.id}", size: 'full')
        elsif mainfile['file_type_tesim'].include? "text"
          is_shown_by   = object_file_url(record.id, mainfile.id, surrogate: 'pdf')
        elsif mainfile['file_type_tesim'].include? "3d"
          is_shown_by = object_3d_url(record)
        end

        xml.tag!("edm:isShownBy",{"rdf:resource" => is_shown_by}) if is_shown_by
        xml.tag!("edm:isShownAt", {"rdf:resource" => landing_page})

        images = 0
        assets.each do |file|
          if file.id != mainfile.id && file.keys.include?("file_type_tesim")

            if file["file_type_tesim"].include? "video"
              url = object_file_url(record.id, file.id, surrogate: 'mp4')
            elsif file["file_type_tesim"].include? "audio"||"sound"
              url = object_file_url(record.id, file.id, surrogate: 'mp3')
            elsif file["file_type_tesim"].include? "text"
              url = object_file_url(record.id, file.id, surrogate: 'pdf')
            elsif file["file_type_tesim"].include? "image"
              next if (images > 0 || (mainfile['file_type_tesim'].include? "image"))
              images += 1
              url = riiif.image_url("#{record.id}:#{file.id}",size: 'full')
            elsif file["file_type_tesim"].include? "3d"
              url =  object_3d_url(record)  
            end

            xml.tag!("edm:hasView", {"rdf:resource" => url})
          end
        end

        # Create the edm:object element
        xml.tag!("edm:object", {"rdf:resource" => thumbnail})
      end

      # If the mainfile is an image, then we create a single webresource and service

      if mainfile["file_type_tesim"].include? "image"
        image_url = riiif.image_url("#{record.id}:#{mainfile.id}", size: 'full')
        manifest_url = iiif_manifest_url("#{record.id}", format: :json)
        base_url = riiif.base_url("#{record.id}:#{mainfile.id}")

        xml.tag!("edm:WebResource", {"rdf:about" => image_url}) do
          xml.tag!("edm:rights", {"rdf:resource" => licence})
          xml.tag!("edm:copyright", {"rdf:resource" => copyright})
          xml.tag!("svcs:has_service", {"rdf:resource" => base_url})
          xml.tag!("dcterms:isReferencedBy", {"rdf:resource" => manifest_url})
        end
        xml.tag!("svcs:Service",{"rdf:about" => base_url}) do
          xml.tag!("dcterms:conformsTo", {"rdf:resource" => 'http://iiif.io/api/image'})
          xml.tag!("doap:implements", {"rdf:resource" => 'http://iiif.io/api/image/2/level2.json'})
        end
      end

      # Get urls for each asset file and create a webResource element
      images = 0
      assets.each do |file|
        if file.keys.include?("file_type_tesim")
          if file['file_type_tesim'].include? "video"
            url = object_file_url(record.id, file.id, surrogate: 'mp4')
          elsif file['file_type_tesim'].include? "audio"||"sound"
            url = object_file_url(record.id, file.id, surrogate: 'mp3')

          elsif file['file_type_tesim'].include? "image" and ! mainfile['file_type_tesim'].include? "image"
            next if (images > 0 || (mainfile['file_type_tesim'].include? "image"))

            image_url = riiif.image_url("#{record.id}:#{file.id}", size: 'full')
            manifest_url = iiif_manifest_url("#{record.id}", format: :json)
            base_url = riiif.base_url("#{record.id}:#{file.id}")

            xml.tag!("edm:WebResource", {"rdf:about" => image_url}) do
              xml.tag!("edm:rights", {"rdf:resource" => licence})
              xml.tag!("edm:copyright", {"rdf:resource" => copyright})
              xml.tag!("svcs:has_service", {"rdf:resource" => base_url})
              xml.tag!("dcterms:isReferencedBy", {"rdf:resource" => manifest_url})
            end
            xml.tag!("svcs:Service",{"rdf:about" => base_url}) do
              xml.tag!("dcterms:conformsTo", {"rdf:resource" => 'http://iiif.io/api/image'})
              xml.tag!("doap:implements", {"rdf:resource" => 'http://iiif.io/api/image/2/level2.json'})
            end
            images+=1
          elsif file['file_type_tesim'].include? "text"
            url = object_file_url(record.id, file.id, surrogate:'pdf')
          elsif file['file_type_tesim'].include? "3d"
            url = object_3d_url(record)
          end

          if !(file['file_type_tesim'].include? "image") && url
            xml.tag!("edm:WebResource", {"rdf:about" => url}) do
              xml.tag!("edm:rights", {"rdf:resource" => licence})
            end
          end
        end
      end

      # Add a WebResource element for the thumbnail url
      xml.tag!("edm:WebResource", {"rdf:about" => thumbnail}) do
        xml.tag!("edm:rights", {"rdf:resource" => licence})
      end

    end

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

  def is_valid_period?(dcmi)
    return true if dcmi['name'].present? && dcmi['start'].present?
    return false
  end

  def is_valid_point?(dcmi)
    return true if dcmi['name'].present? && dcmi['north'].present? && dcmi['east'].present?
    return false
  end

  def valid_url?(url)
    uri = URI.parse(url)
    (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  def self.edm_type(types)
    types = types.map(&:upcase)
    return "3D" if types.include?(Settings.edm._3d)
    return "VIDEO" if types.to_set.intersect?(Settings.edm.video .to_set)
    return "SOUND" if types.to_set.intersect?(Settings.edm.sound.to_set)
    return "TEXT" if types.include?(Settings.edm.text)
    return "IMAGE" if types.to_set.intersect?(Settings.edm.image.to_set)
    return "INVALID"
  end

  def doi_url(record, doi_from_metadata=false)
    # Check whether we are supposed to use the provider's DOI
    if (doi_from_metadata)
      if record['source_tesim']
        record['source_tesim'].find { |e| /(https:\/\/doi\.org.*\/.*)/ =~ e }
        return $1 unless $1.blank?
      end
      if record['qdc_id_tesim']
        record['qdc_id_tesim'].find { |e| /(https:\/\/doi\.org.*\/.*)/ =~ e }
        return $1 unless $1.blank?
      end
    end

    return nil if record.doi.blank?
    if record.doi.is_a? Array
      doi = record.doi.first
    else
      doi = record.doi
    end
    "https://doi.org/#{doi}"
  end

  # Get the main file where there is more than one file
  def self.mainfile_for_type(edmtype, assets, iiif_main=false)
    case edmtype
    when "VIDEO"
      assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "video" }
    when "SOUND"
      assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "audio" || "sound" }
    when "TEXT"
      if (iiif_main)
        assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "image" }
      else
        assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "text" } ||
          assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "image" }
      end
    when "IMAGE"
      assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "image" }
    when "3D"
       assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "3d" }
    else
      nil
    end
  end

  def thumbnail_url(record, edmtype, file, image=nil)
    if file['file_type_tesim'].include? "video"
      object_file_url(record.id, file.id, surrogate: 'thumbnail')
    elsif file['file_type_tesim'].include? "audio"||"sound"
      if image.present?
        object_file_url(record.id, image.id, surrogate: 'lightbox_format')
      else
        cover_image_url(record.collection_id)
      end
    elsif file['file_type_tesim'].include? "text"
      if image.present?
        riiif.image_url("#{record.id}:#{image.id}", size: '500,')
      else
        object_file_url(record.id, file.id, surrogate: 'lightbox_format')
      end
    elsif file['file_type_tesim'].include? "image"
      riiif.image_url("#{record.id}:#{file.id}", size: '500,')
    elsif file['file_type_tesim'].include? "3d" 
       if image.present?
        object_file_url(record.id, image.id, surrogate: 'lightbox_format')
      else
        cover_image_url(record.collection_id)
      end
    else
      nil
    end
  end

  # Remove any formats that we don't want to aggregated from the assets list
  # Currently just xml files as pdf surrogates
  def clean_assets(assets)
    assets.select { |obj| obj.key? 'file_type_tesim' and !obj['mime_type_tesim'].include? "text/xml" }
  end
  
  def object_3d_url(record)
    api_oembed_url+"?url="+catalog_url(record.id)
  end

  def valid?(record)
    return false unless record.published?
    return false if record.assets.size < 1
    # We are not going to aggregate restricted assets to Europeana
    return false unless record.public_read?
    
    true
  end
end
