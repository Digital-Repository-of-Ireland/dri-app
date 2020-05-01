class IiifController < ApplicationController
  include Blacklight::AccessControls::Catalog
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
    iiif_respond do
      Rails.cache.fetch(
        "#{@document.id}-#{@document['system_modified_dtsi']}"
      ) { iiif_manifest.as_json }
    end
  end

  def sequence
    iiif_respond do
      Rails.cache.fetch(
        "#{@document.id}-iiif-sequence-#{@document['system_modified_dtsi']}"
      ) { iiif_sequence.as_json }
    end
  end

  private

    def iiif_respond
      @document = solr_doc_by_id_param
      response.headers['Access-Control-Allow-Origin'] = '*'

      manifest = yield

      respond_to do |format|
        format.html  { @manifest = JSON.pretty_generate(manifest) }
        format.json  { render json: manifest, content_type: 'application/ld+json' }
      end
    end

    def solr_doc_by_id_param
      enforce_permissions!('show_digital_object', params[:id])
      document = SolrDocument.find(params[:id])

      unless document && (document.collection? || can?(:read, document.id))
        raise Hydra::AccessDenied.new(t('dri.views.exceptions.access_denied'))
      end
      document
    end

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
