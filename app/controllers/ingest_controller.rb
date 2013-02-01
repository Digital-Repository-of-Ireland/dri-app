# Controller for Ingesting
#

require 'stepped_forms'

class IngestController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include DRI::Model
  include SteppedForms

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Form for a new dri_data_models model.
  #
  def new
    reset_ingest_state
    @current_step = session[:ingest][:current_step]

    respond_to do |format|
      format.html
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
    if params[:dri_model][:collection_id]
      collection = Collection.find(params[:dri_model][:collection_id])
      @document_fedora.collection = collection
    end
    @document_fedora.update_attributes(params[:dri_model])

    respond_to do |format|
      flash["notice"] = "Updated " << params[:id]
      format.html  { render :action => "edit" }
      format.json  { render :json => @document_fedora }
    end
  end

  # Creates a new model using the parameters passed in the request.
  #
  def create
    #Merge our object data so far and create the model
    session[:object_params].deep_merge!(params[:dri_model]) if params[:dri_model]

    if !session[:ingest][:type].nil? && !session[:ingest][:type].eql?("")
      if session[:ingest][:type].eql?('audio')
        @document_fedora = DRI::Model::DigitalObject.construct(:Audio, session[:object_params])
      elsif session[:ingest][:type].eql?('pdfdoc')
        @document_fedora = DRI::Model::DigitalObject.construct(:Pdf, session[:object_params])
      end
    else
      @document_fedora = DRI::Model::DigitalObject.construct(:Audio, session[:object_params])
    end

    @ingest_methods = get_ingest_methods
    @supported_types = get_supported_types

    # which step am I on? This should be moved to a separate controller so that the
    # objects controller doesn't need to care about steps
    if last_step?
      # Last step, now we should create and save the object
      if params[:dri_model][:collection_id]
        collection = Collection.find(params[:dri_model][:collection_id])
        @document_fedora.add_relationship(:is_member_of, collection)
      end
      if @document_fedora.valid? && @document_fedora.save
        reset_ingest_state
        respond_to do |format|
          format.html { flash[:notice] = "Digital object has been successfully ingested."
            redirect_to :controller => "catalog", :action => "show", :id => @document_fedora.id }
          format.json { render :json => @document_fedora }
        end
      else
        respond_to do |format|
          format.html {
            flash["alert"] = @document_fedora.errors.messages.values.to_s
            render :action => :new
          }
          format.json { render :json => @document_fedora.errors}
        end
      end
    else
      # Continue was pressed on a non-final step, increment the current step
      # and update session state
      update_ingest_state
      @current_step = session[:ingest][:current_step]
      render :action => :new
    end

  end

end

