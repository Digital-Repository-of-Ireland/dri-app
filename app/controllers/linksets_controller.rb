class LinksetsController < ApplicationController
  require 'json'
  require 'net/http'
  require 'uri'

  def lset
    id = params[:id]

    @document = solr_request(id, true)
    linkset = formatter.format

    response.headers['Content-Type'] = 'application/linkset'
    render plain: linkset.join(" , \n")+"\n\n"
  end

  def json
    id = params[:id]

    @document = solr_request(id, true)
    linkset = formatter.format({format: :json})
   
    response.headers['Content-Type'] = 'application/linkset+json'
    render json: "#{linkset}\n\n"
  end

  private

   def formatter
     @formatter ||= ::DRI::Formatters::Linkset.new(self, @document)
   end

   def solr_request(id_target, is_essential)
     @document = SolrDocument.find("#{id_target}")

     if @document.present? && @document.linkset?
       return @document
     else
       raise DRI::Exceptions::BadRequest, 'Invalid ID provided'
     end
   end
end
