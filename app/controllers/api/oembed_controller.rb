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
        
        type = get_type(doc["type_tesim"])
      
        assets = doc.assets(with_preservation: true, ordered: false)
        mainfile = file_for_type(type, assets)

         if mainfile['file_type_tesim'].include? "3d"
          embed_url = file_download_path(doc.id, mainfile.id, type: 'masterfile') 
         end 
       
        raise DRI::Exceptions::NotFound if embed_url.nil?
      
        # Build up a JSON response with the required attributes
        # See "2.3.4. Response parameters" at https://oembed.com/
        @response = {
          type: 'Rich',
          version: '1.0',
          title: doc['title_tesim'], # assuming this is the name of your resource
          provider_name: 'DRI: Digital Repository of Ireland',
          provider_url: 'https://www.dri.ie/',
        
          # not sure if this width and height is correct
          width: 500,
          height: 500,
          # Some pseudo-code to demonstrate that your action
          # will need to return the embed code to the model from the given page
          html: <<-HTML
          
          <iframe src = " #{embed_url}">

          </iframe> 

          HTML
        }   
        
        respond_to do |format|         
           format.json { render(json: @response)} 
           format.xml  { render :xml => @response}              
           format.any   { raise DRI::Exceptions::NotImplemented }
           
        end

  
     end

  def  get_type(types)
       types = types.map(&:upcase)
       return "3D" if types.include?("3D")    
  end

  def file_for_type(type, assets)
   case type
     when "3D"
      assets.find(ifnone = nil) { |obj| obj.key? 'file_type_tesim' and obj['file_type_tesim'].include? "3d" }
     else
      nil
     end  
  end

private
 
  def set_headers
      response.content_type == "application/json+oembed"
      response.headers["Access-Control-Allow-Origin"] = "*"

  end
# shoud I move it to application controller? as its duplicate of method from access_controller





 end

end	