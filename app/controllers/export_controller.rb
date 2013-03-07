# Controller for Exporting digital objects
#

class ExportController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include DRI::Model

  before_filter :authenticate_user!, :only => [:show]

  # Exports an entire digital object as a tar.gz archive
  #
  def show
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
  end

end

