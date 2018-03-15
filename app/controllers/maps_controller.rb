class MapsController < ApplicationController
  def show
    object = retrieve_object!(params[:id])

    @document = SolrDocument.new(object.to_solr)
    @request_controller = params[:request_controller]
  end
end
