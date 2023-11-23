class SignpostingHeaderLsetController < ApplicationController
    include SignpostingHeaderHelper
    require 'json'
    require 'net/http'
    require 'uri'
    
    def lset
        id = params[:id]

        @document = solr_request(id, true)
        
        schema_link = mapped_links(@document.type, SCHEMA_TYPES)
        
        doi = DataciteDoi.where(object_id: @document.id).current
        @doi = doi.doi if doi.present? && doi.minted?
        
        orcid_links = get_contributors(@document['contributor_tesim'])
        
        license_link = @document.licence.url
    
        assets = @document.assets
        link_assets = object_items(assets, id)
    
        describedby = metadata_link(id)
    
        linkset = []
    
        if @doi.present?
            linkset << "<#{"https://doi.org/"+ doi.doi}> ; rel=\"cite-as\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""
        end

        if schema_link.present?
          linkset << "<#{schema_link}> ; rel=\"type\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""
        end
        linkset << "<https://schema.org/AboutPage> ; rel=\"type\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""

        if orcid_links.present?
            orcid_links.each do |orcid|
                linkset << "<#{orcid}> ; rel=\"author\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""
            end
        end

        if link_assets.present?
            link_assets.each do |asset|
                linkset << "<#{asset[:href]}> ; rel=\"item\" ; type=\"#{asset[:type]}\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""
            end
        end

        linkset << "<#{describedby[:href]}> ; rel=\"describedby\" ; type=\"application/xml\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""

        if license_link.present?
          linkset << "<#{license_link}> ; rel=\"license\" ; anchor=\"https://repository.dri.ie/catalog/#{id}\""
        end

        ancestor_id = @document['ancestor_id_ssim']

        reverse_link = reverse_link_builder(link_assets, ancestor_id, id)
        reverse_link.each do |item|
            item_json = JSON.parse(item.to_json)
            linkset << "<#{item_json["collection"][0]["href"]}> ; rel=\"collection\" ; type=\"#{item_json["collection"][0]["type"]}\" ; anchor=\"#{item_json["anchor"]}\""
        end

        response.headers['Content-Type'] = 'application/linkset'
        render plain: linkset.join(" , \n")+"\n\n"
    end
end
