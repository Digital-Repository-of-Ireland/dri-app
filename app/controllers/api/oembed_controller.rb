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
       
        doc = SolrDocument.find(resource_id)

        read_master = doc.read_master? ? 'public' : 'private'
        
        if read_master.include? 'private'
           raise DRI::Exceptions::Unauthorized
        end  
        
        type =   DRI::Formatters::EDM.edm_type(doc["type_tesim"])
        assets = doc.assets(with_preservation: true, ordered: false)

        mainfile = DRI::Formatters::EDM.mainfile_for_type(type, assets)

         if mainfile['file_type_tesim'].include? "3d"
          embed_url = file_download_path(doc.id, mainfile.id, type: 'masterfile') 
         end 
       
        raise DRI::Exceptions::NotFound if embed_url.nil?
      
        # Build up a JSON response with the required attributes
        # See "2.3.4. Response parameters" at https://oembed.com/
        @response = {
          type: 'Rich',
          version: '1.0',
          title: doc['title_tesim'], # assuming this is the name of resource
          provider_name: 'DRI: Digital Repository of Ireland',
          provider_url: 'https://repository.dri.ie/',
        
          # not sure if this width and height is correct 
          width: 500,
          height: 500,

          # Embedding url 
          
          html: <<-HTML
          
          <iframe src = " #{embed_url}">

          </iframe> 

          HTML
        }   
        
        respond_to do |format|         
          if @response
           format.json { render(json: @response)} 
           format.xml  { render :xml => @response}              
           else  
           format.All   { raise DRI::Exceptions::NotImplemented }
          end
        end

  
     end

    private
     
      def set_headers
          if request.format.json?
          response.content_type == "application/json+oembed"
          elsif request.format.xml?
           response.content_type == "text/xml+oembed" 
          end
          response.headers["Access-Control-Allow-Origin"] = "*"
      end


   end

end	