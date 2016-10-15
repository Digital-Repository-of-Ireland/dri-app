class IiifController < CatalogController
  include DRI::IIIFViewable

  def show
  end

  def manifest
    enforce_permissions!('show_digital_object', params[:id])
    
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([params[:id]])
    results = ActiveFedora::SolrService.query(query, rows: 1)
    @object = SolrDocument.new(results.first)

    unless (@object.collection? || can?(:read, @object.id))
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied'))
    end

    response.headers['Access-Control-Allow-Origin'] = '*'

    respond_to do |format|
      format.html  { @manifest = iiif_manifest.to_json(pretty: true) }
      format.json  { render json: iiif_manifest.to_json, content_type: 'application/ld+json' }
    end
  end

  def view
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])
    @document = SolrDocument.new(@object.to_solr)

    render layout: false
  end

end