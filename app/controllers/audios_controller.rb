class AudiosController < ApplicationController
  include Blacklight::Catalog
  # include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  # include Hydra::Controller::ControllerBehavior
  # include Hydra::AssetsControllerHelper
  # include Hydra::AccessControlsEnforcement
  # include Blacklight::Configurable
  include DRI::Model
  # include DRI::Metadata

  # self.copy_blacklight_config_from(CatalogController)

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  def new
    @document_fedora = DRI::Model::Audio.new
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  def edit
    #@document_fedora = Audio.new
    @document_fedora = Audio.find(params[:id])
    #@document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    #respond_to do |format|
    #  format.html
    #  format.json  { render :json => @document_fedora }
    #end
  end

  def show
    # update_session
    # session[:viewing_context] = "browse"
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    #respond_to do |format|
    #  format.html  
    #  format.json  { render :json => @document_fedora }
    #end
  end

  def update
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    @document_fedora.update_attributes(params[:fedora_document])
    redirect_to :edit
  end

  def create
    @document_fedora = DRI::Model::Audio.new(params[:document_fedora])
    respond_to do |format|
      if @document_fedora.save
        format.html {redirect_to :edit}
        format.json {}
      else
        format.html {
          flash["alert"] = @document_fedora.errors.messages.values.to_s
          render :action => "new"
        }
        format.json { render :json => @document_fedora.errors}
      end
    end
  end
end

