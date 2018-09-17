class IiifController < ApplicationController
  include Hydra::AccessControlsEnforcement
  include DRI::IIIFViewable

  def show
    id = params[:id].split(':')[0]
    access = permitted?(params[:method], id)
    
    if access
      head :ok, content_type: "text/html"
    else
      head :unauthorized, content_type: "text/html"
    end
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

    manifest = Rails.cache.fetch("#{@document.id}-#{@document['system_modified_dtsi']}") { iiif_manifest.to_json }
    
    respond_to do |format|
      format.html  { @manifest = JSON.pretty_generate JSON.parse(manifest) }
      format.json  { render json: manifest, content_type: 'application/ld+json' }
    end
  rescue Blacklight::Exceptions::InvalidSolrID => e
    # TODO look into blacklight handling 404s same as my_collections controller
    respond_to do |format|
      format.html  { render file: "#{Rails.root}/public/404.html", layout: false, status: 404 }
      format.json  { render json: {status: "404", error: "#{e}"}, content_type: 'application/ld+json', status: 404 }
    end
    return
  end

  private

    def permitted?(method, id)
      resp = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax', rows: '1')
      object_doc = SolrDocument.new(resp.first)
      
      if method == 'show'
        object_doc.published? && object_doc.public_read?
      elsif method == 'info'
        object_doc.published?
      end
    end
end
