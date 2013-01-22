# Controller for the Audio model
#
class AudiosController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include DRI::Model

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Creates a new Audio model.
  #
  def new
    @document_fedora = DRI::Model::Audio.new
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  # Edits an existing model.
  #
  def edit
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  # Retrieves an existing model.
  #
  def show
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    respond_to do |format|
      format.html  
      format.json  { render :json => @document_fedora }
    end
  end

  # Updates the attributes of an existing model.
  #
  def update
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    
    @document_fedora.update_attributes(params[:dri_model_audio])
    respond_to do |format|
      flash["notice"] = "Updated " << params[:id]
      format.html  { render :action => "edit" }
      format.json  { render :json => @document_fedora }
    end
  end

  # Creates a new audio model using the parameters passed in the request.
  #
  def create
    @document_fedora = DRI::Model::Audio.new(params[:dri_model_audio])
    respond_to do |format|
      if @document_fedora.valid? && @document_fedora.save
        format.html { flash[:notice] = "Audio object has been successfully ingested."
            redirect_to :controller => "catalog", :action => "show", :id => @document_fedora.id }
        format.json { render :json => @document_fedora }
      else
        format.html {
          flash["alert"] = @document_fedora.errors.messages.values.to_s
          render :action => :new
        }
        format.json { render :json => @document_fedora.errors}
      end
    end
  end

end

