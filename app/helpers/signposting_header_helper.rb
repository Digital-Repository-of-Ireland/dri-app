module SignpostingHeaderHelper
  require 'json'

  private

    SCHEMA_TYPES = {
      'text' 			          => 'https://schema.org/DigitalDocument',
      'image' 			        => 'https://schema.org/ImageObject',
      'movingimage' 		    => 'https://schema.org/VideoObject',
      'interactiveresource' => 'https://schema.org/WebApplication',
      'sound' 			        => 'https://schema.org/AudioObject',
      'software' 		        => 'https://schema.org/SoftwareApplication',
      'dataset' 			      => 'https://schema.org/Dataset',
      'article'             => 'https://schema.org/ScholarlyArticle',
      'collection'          => 'https://schema.org/Collection',
      'object'              => 'https://schema.org/object',
      '3d'                  => 'https://schema.org/3DModel'
    }.freeze

    XML_PROFILE = {
      'DRI::QualifiedDublinCore'  => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd',
      'DRI::Mods'                 => 'http://www.loc.gov/standards/mods/v3/mods-3-7.xsd',
      'DRI::EadComponent'         => 'http://www.loc.gov/ead/ead.xsd',
      'DRI::EadCollection'        => 'http://www.loc.gov/ead/ead.xsd',
      'DRI::Marc'                 => 'http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
    }.freeze

    def solr_request(id_target, is_essential)
      @document = SolrDocument.find("#{id_target}")

      if @document.present? && @document.object? && @document['file_count_isi'].present? && @document.published?
        return @document
      else
        raise DRI::Exceptions::BadRequest, 'Invalid ID provided'
      end
    end

    def mapped_links (target_types, map)
      target_types.each do |type|
        link = map[type]
        if link.present?
          return link
        end
      end
      
      nil
    end

    def get_contributors(contributors)
      return nil unless contributors.present?
      
      identifiers = contributors.map do |entry|
        match = entry.match(/identifier=(https:\/\/orcid\.org\/\d{4}-\d{4}-\d{4}-\d{4})/)
        match&.captures&.first
      end.compact
        
      identifiers
    end
  
    def object_items(assets, id)
      asset_link = []
      assets.each do |asset|
        id_file = asset&.fetch("id", nil).to_s.gsub(/[\[\]"]/, '')
        mime_type = asset&.fetch("mime_type_tesim", nil).to_s.gsub(/[\[\]"]/, '')

        if asset.text? || asset.pdf?
          if mime_type.include?('application/pdf')
            item_link(asset, id, asset_link, "surrogate", id_file, mime_type)
          else 
            item_link(asset, id, asset_link, "surrogate", id_file, "application/pdf")
            if @document.read_master? && asset.text? && !mime_type.include?('application/pdf')
              item_link(asset, id, asset_link, "masterfile", id_file, mime_type)
            end
          end
        elsif asset.threeD?
          if @document.read_master?
            item_link(asset, id, asset_link, "masterfile", id_file, mime_type)
          else
            item_link(asset, id, asset_link, "surrogate", id_file, mime_type)
          end
        else
          item_link(asset, id, asset_link, "surrogate", id_file, mime_type)
        end
      end

      asset_link
    end

    def item_link(asset, id, asset_link, type, id_file, mime_type)
      place_holder = {}
      file = "https://repository.dri.ie/objects/#{id}/files/#{id_file}/download?type=#{type}"
      place_holder[:href] = file
      place_holder[:type] = mime_type
      asset_link << place_holder
    end
  
    def metadata_link(id)
      describedby_link = {}
      metadata_type = "application/xml"
      metadata_url = "https://repository.dri.ie/objects/#{id}/metadata"
      describedby_link [:href] = metadata_url
      describedby_link [:type] = metadata_type
      xml_type = @document['has_model_ssim']
      profile = mapped_links(xml_type, XML_PROFILE)

      if profile.present?
        describedby_link [:profile] = profile
      end

      describedby_link
    end

    def reverse_link_builder (link_assets, ancestor_id, object_id)
      reverse = []
      ancestor_link = "https://repository.dri.ie/catalog/#{ancestor_id.first}" 
      object_link = "https://repository.dri.ie/catalog/#{object_id}" 
      
      link_assets.each do|item|
        place_holder = {}
        arr_holder = []
        collection = {}
        collection[:href] = ancestor_link
        collection[:type] = "text/html"
        arr_holder << collection
        anchor = item.to_a
        place_holder[:anchor] = anchor[0][1] || nil
        place_holder[:collection] = arr_holder
        reverse << place_holder
      end

      reverse
    end
  end