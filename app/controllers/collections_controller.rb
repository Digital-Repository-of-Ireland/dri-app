# Controller for the Collection model
#
class CollectionsController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include DRI::Model

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Shows list of user's collections
  #
  def index
    @mycollections = DRI::Model::Collection.all
  end

  # Creates a new model.
  #
  def new
    @document_fedora = DRI::Model::Collection.new

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
    
    @document_fedora.update_attributes(params[:dri_model_collection])
    respond_to do |format|
      flash["notice"] = t('dri.flash.notice.updated', :item => params[:id])
      format.html  { render :action => "edit" }
      format.json  { render :json => @document_fedora }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    @document_fedora = DRI::Model::Collection.new(params[:dri_model_collection])
    #@document_fedora.creator = current_user.to_s
    respond_to do |format|
      if @document_fedora.save
        format.html { flash[:notice] = t('dri.flash.notice.collection_created')
            redirect_to :controller => "collections", :action => "show", :id => @document_fedora.id }
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

