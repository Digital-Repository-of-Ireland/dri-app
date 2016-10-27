class IiifController < CatalogController
  include DRI::IIIFViewable

  def show
  end

  def manifest
    enforce_permissions!('show_digital_object', params[:id])
    
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]])
    results = ActiveFedora::SolrService.query(query, rows: 1)
    @document = SolrDocument.new(results.first)
  
    unless (@document.collection? || can?(:read, @document.id))
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied'))
    end

    response.headers['Access-Control-Allow-Origin'] = '*'

    manifest = Rails.cache.fetch(params[:id]) { iiif_manifest.to_json }
    
    respond_to do |format|
      format.html  { @manifest = JSON.pretty_generate JSON.parse(manifest) }
      format.json  { render json: manifest, content_type: 'application/ld+json' }
    end
  end

end