class IiifController < CatalogController
  include DRI::IIIFViewable

  def show
  end

  def manifest
    enforce_permissions!('show_digital_object', params[:id])
    
    @object = retrieve_object!(params[:id])

    unless (@object.collection? || can?(:read, params[:id]))
      raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied'))
    end

    response.headers['Access-Control-Allow-Origin'] = '*'
    render json: iiif_manifest.to_json, content_type: 'application/ld+json'
  end

  def view
    enforce_permissions!('show_digital_object', params[:id])

    @object = retrieve_object!(params[:id])
    @document = SolrDocument.new(@object.to_solr)
  end

end