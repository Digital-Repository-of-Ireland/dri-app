class MapsController < ApplicationController
  def show
    @document = SolrDocument.find(params[:id])
    @request_controller = params[:request_controller]
  end
end
