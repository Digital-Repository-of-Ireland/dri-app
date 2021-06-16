module Api
  require 'solr/query'

  class OembedController < ApplicationController
    include Blacklight::AccessControls::Catalog

    before_action :set_headers

    def show
      url = params.fetch(:url)
      resource_url = URI.parse(url)
      # Extract the resource ID from the path
      resource_id = resource_url.path.match(%r|/catalog/([^/]+)|)
      resource_id &&= resource_id[1]
      raise DRI::Exceptions::BadRequest unless resource_id

      doc = SolrDocument.find(resource_id)
      raise DRI::Exceptions::Unauthorized unless can_view?(doc)

      type =   DRI::Formatters::EDM.edm_type(doc["type_tesim"])
      assets = doc.assets(with_preservation: true, ordered: false)

      mainfile = DRI::Formatters::EDM.mainfile_for_type(type, assets)

      if has_3d_type?(mainfile)
        embed_url = embed3d_display_url(doc.id, mainfile.id)
      end

      raise DRI::Exceptions::NotFound if embed_url.nil?

      resource_title = doc['title_tesim']

      # Build up a JSON response with the required attributes
      # See "2.3.4. Response parameters" at https://oembed.com/
      @response = {
        type: 'rich',
        version: '1.0',
        title: resource_title[0],
        provider_name: 'DRI: Digital Repository of Ireland',
        provider_url: 'https://repository.dri.ie/',
        width: 560,
        height: 315,
        # Embedding url

        html: <<-HTML
        <iframe src = "#{embed_url}" width="560px" height="315px">
        </iframe>
        HTML
      }

      respond_to do |format|
        if @response
          format.json { render json: @response }
          format.xml  { render xml: @response }
        else
          format.all  { raise DRI::Exceptions::NotImplemented }
        end
      end
   end

    private
      def can_view?(doc)
        (can?(:read, doc.id) && doc.read_master?) || can?(:edit, doc)
      end

      def has_3d_type?(file)
        file.fetch('file_type_tesim',[]).include?('3d')
      end

      def set_headers
        response.headers["Access-Control-Allow-Origin"] = "*"
      end
   end
end
