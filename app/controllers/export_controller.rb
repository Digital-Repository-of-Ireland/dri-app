# Controller for Exporting digital objects
#

class ExportController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior

  before_filter :authenticate_user!, :only => [:show]

  # Exports an entire digital object
  #
  def show
    begin
      @document = ActiveFedora::FixtureExporter.export(params[:id])
      render :xml => @document    
    rescue ActiveFedora::ObjectNotFoundError => e
      render :xml => { :error => 'Not found' }, :status => 404
      return
    end
  end

end

