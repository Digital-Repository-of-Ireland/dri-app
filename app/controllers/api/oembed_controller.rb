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
      raise DRI::Exceptions::NotFound if mainfile.nil?

      if has_3d_type?(mainfile)
        embed_url = embed3d_display_url(doc.id, mainfile.id)
      end

      raise DRI::Exceptions::NotFound if embed_url.nil?

      resource_title = doc['title_tesim']

      # Build up a JSON response with the required attributes
      # See "2.3.4. Response parameters" at https://oembed.com/

      if embed_url
        @response = {
          type: 'rich',
          version: '1.0',
          title: resource_title[0],
          provider_name: 'DRI: Digital Repository of Ireland',
          provider_url: 'https://repository.dri.ie/',
            width: 560,
            height: 315,
          html: generate_iframe(embed_url)
        }
      end


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

      def generate_iframe(url)
        # Escape the URL to prevent XSS attacks
        escaped_url = CGI.escapeHTML(url)
        
        # Use single quotes for attribute values to avoid issues with double quotes inside the URL
        iframe_html = "<iframe src='#{escaped_url}' width='100%' height='100%' frameborder='0'></iframe>"
        
        return iframe_html
      end

      def can_view?(doc)
        (can?(:read, doc.id) && doc.read_master?) || can?(:edit, doc)
      end

      def has_3d_type?(file)
        file.present? && file.fetch('file_type_tesim', []).include?('3d')
      end    

      def set_headers
        response.headers["Access-Control-Allow-Origin"] = "*"
      end
    end
end
