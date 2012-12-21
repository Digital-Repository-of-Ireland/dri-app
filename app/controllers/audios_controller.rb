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

  #self.copy_blacklight_config_from(CatalogController)

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]
  # before_filter :enforce_access_controls
  # before_filter :enforce_asset_creation_restrictions, :only=>[:new, :create]

  def new
    @document_fedora = DRI::Model::Audio.new
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  def edit
    #@document_fedora = Audio.find(params[:id])
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    respond_to do |format|
      format.html
      format.json  { render :json => @document_fedora }
    end
  end

  def show
    # update_session
    # session[:viewing_context] = "browse"
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    respond_to do |format|
      format.html  
      format.json  { render :json => @document_fedora }
    end
  end

  def update
    @document_fedora = ActiveFedora::Base.find(params[:id], {:cast => true})
    changes = changed_fields(params)
    @document_fedora.update_attributes(params[:dri_model_audio])
    respond_to do |format|
      flash["alert"] = "Updated " << params[:id]
      format.html  { render :action => "edit" }
      format.json  { render :json => @document_fedora }
    end
  end

  def create
    @document_fedora = DRI::Model::Audio.new(params[:document_fedora])
    respond_to do |format|
      if @document_fedora.save
        format.html {render :action => :edit}
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

  def changed_fields(params)
    changes = Hash.new
    return changes if params[:dri_model_audio].nil?
    object = ActiveFedora::Base.find(params[:id], {:cast => true})
    logger.info("\n\n\n\n\n" + params[:document_fields].inspect + "\n\n\n\n\n\n")
    params[:dri_model_audio].each do |k,v|
      if params[:dri_model_audio][k.to_sym].kind_of?(Array)
        unless object.send(k.to_sym) == v or (object.send(k.to_sym).empty? and v.first.empty?) or (v.sort.uniq.count > object.send(k.to_sym).count and v.sort.uniq.first.empty?)
          changes.store(k,v)
        end
      else
        unless object.send(k.to_sym) == v
          changes.store(k,v)
        end
      end
    end
    return changes
  end
end

