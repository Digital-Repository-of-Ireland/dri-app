class DRI::Formatters::Linkset
  require 'json'

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

    def initialize(controller, document, options = {})
      @controller = controller
      @document = document
    end

    def format(options = {})
      output_format = options[:format].presence || :lset
      output_format == :lset ? lset : json
    end

    def lset
      schema_link = mapped_links(@document.type)
        
      doi = DataciteDoi.where(object_id: @document.id).current
      @doi = doi.doi if doi.present? && doi.minted?
          
      orcid_links = contributors  
      license_link = @document.licence.url
      copyright_link = @document.copyright.url
      
      assets = @document.assets
      link_assets = object_items(assets, @document.id)

      describedby = metadata_link
      linkset = []
      
      anchor_url = @controller.catalog_url(@document.id)
      if @doi.present?
        linkset << "<#{"https://doi.org/"+ doi.doi}> ; rel=\"cite-as\" ; anchor=\"#{anchor_url}\""
      end

      if schema_link.present?
        linkset << "<#{schema_link}> ; rel=\"type\" ; anchor=\"#{anchor_url}\""
      end
      linkset << "<https://schema.org/AboutPage> ; rel=\"type\" ; anchor=\"#{anchor_url}\""

      if orcid_links.present?
        orcid_links.each do |orcid|
          linkset << "<#{orcid}> ; rel=\"author\" ; anchor=\"#{anchor_url}\""
        end
      end

      if link_assets.present?
        link_assets.each do |asset|
          linkset << "<#{asset[:href]}> ; rel=\"item\" ; type=\"#{asset[:type]}\" ; anchor=\"#{anchor_url}\""
        end
      end

      linkset << "<#{describedby[:href]}> ; rel=\"describedby\" ; type=\"application/xml\" ; anchor=\"#{anchor_url}\""
      if license_link.present?
        linkset << "<#{license_link}> ; rel=\"license\" ; anchor=\"#{anchor_url}\""
      end

      if copyright_link.present?
        linkset << "<#{copyright_link}> ; rel=\"copyright\" ; anchor=\"#{anchor_url}\""
      end

      ancestor_id = @document['ancestor_id_ssim']
      reverse_link = reverse_link_builder(link_assets, ancestor_id, @document.id)
      reverse_link.each do |item|
        item_json = JSON.parse(item.to_json)
        linkset << "<#{item_json["collection"][0]["href"]}> ; rel=\"collection\" ; type=\"#{item_json["collection"][0]["type"]}\" ; anchor=\"#{item_json["anchor"]}\""
      end

      linkset
    end

    def json
      schema_link = mapped_links(@document.type);
     
      doi = DataciteDoi.where(object_id: @document.id).current
      @doi = doi.doi if doi.present? && doi.minted?

      orcid_links = contributors
      license_link = @document.licence.url
      copyright_link = @document.copyright.url

      assets = @document.assets
      link_assets = object_items(assets, @document.id)
        
      describedby = metadata_link
      linkset = {}
      linkset[:anchor] = @controller.catalog_url(@document.id)

      if @doi.present?
        linkset[:"cite-as"] = [{"href" => "https://doi.org/"+ doi.doi}] 
      end
      linkset[:type] = if schema_link.present?
                         [{"href" => schema_link},{"href" => "https://schema.org/AboutPage"}]
                       else
                         [{"href" => "https://schema.org/AboutPage"}]
                       end

      if orcid_links.present?
        orcid = []
        orcid_links.each do |author|
          holder = {}
          holder[:href] = author
          orcid << holder
        end
        linkset[:author] = orcid  
      end

      linkset[:item] = link_assets if link_assets.present?
      linkset[:describedby] = [describedby]
      linkset[:license] = [{"href" => license_link}] if license_link.present?
      linkset[:copyright] = [{"href" => copyright_link}] if copyright_link.present?

      ancestor_id = @document['ancestor_id_ssim']
      reverse_link = reverse_link_builder(link_assets, ancestor_id, @document.id)

      linkset_hash = { "linkset" => [linkset, reverse_link] }

      JSON.pretty_generate(linkset_hash)
    end

    def mapped_links(target_types, map = SCHEMA_TYPES)
      target_types.each do |type|
        link = map[type]
        return link if link.present?
      end
      
      nil
    end

    def contributors
      return nil unless @document['contributor_tesim'].present?
      
      @document['contributor_tesim'].map do |entry|
        match = entry.match(/identifier=(https:\/\/orcid\.org\/\d{4}-\d{4}-\d{4}-\d{4})/)
        match&.captures&.first
      end.compact
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
      file = @controller.file_download_url(id: id_file, object_id: id, type: 'surrogate')
      place_holder[:href] = file
      place_holder[:type] = mime_type
      asset_link << place_holder
    end
  
    def metadata_link
      describedby_link = {}
      metadata_type = "application/xml"
      metadata_url = @controller.object_metadata_url(@document.id)
      describedby_link[:href] = metadata_url
      describedby_link[:type] = metadata_type
      xml_type = @document['has_model_ssim']
      profile = mapped_links(xml_type, XML_PROFILE)

      describedby_link[:profile] = profile if profile.present?

      describedby_link
    end

    def reverse_link_builder(link_assets, ancestor_id, object_id)
      reverse = []
      ancestor_link = @controller.catalog_url(ancestor_id.last) 
      object_link = @controller.catalog_url(object_id)
      
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