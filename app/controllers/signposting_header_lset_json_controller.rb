class SignpostingHeaderLsetJsonController < ApplicationController
  include SignpostingHeaderHelper
  require 'json'
  require 'net/http'
  require 'uri'

  def json
    id = params[:id]

    @document = solr_request(id, true)
    
    schema_link = mapped_links(@document.type, SCHEMA_TYPES);
     
    doi = DataciteDoi.where(object_id: @document.id).current
    @doi = doi.doi if doi.present? && doi.minted?

    orcid_links = get_contributors(@document['contributor_tesim'])
    
    license_link = @document.licence.url

    assets = @document.assets
    link_assets = object_items(assets, id)
      
    describedby = metadata_link(id)

    linkset = {}

    linkset[:anchor] = "https://repository.dri.ie/catalog/#{id}"

    if @doi.present?
      linkset[:"cite-as"] = [{"href" => "https://doi.org/"+ doi.doi}] 
    end

    if schema_link.present?
      linkset[:type] = [{"href" => schema_link},{"href" => "https://schema.org/AboutPage"}]
    else
      linkset[:type] = [{"href" => "https://schema.org/AboutPage"}]
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

    if link_assets.present?
      linkset[:item] = link_assets
    end

    linkset[:describedby] = [describedby]

    if license_link.present?
      linkset[:license] = [{"href" => license_link}]
    end

    ancestor_id = @document['ancestor_id_ssim']
    reverse_link = reverse_link_builder(link_assets, ancestor_id, id)

    linkset_hash = { "linkset" => [linkset, reverse_link] }
    response.headers['Content-Type'] = 'application/linkset+json'
    render json: JSON.pretty_generate(linkset_hash) + "\n\n"
  end
end
  