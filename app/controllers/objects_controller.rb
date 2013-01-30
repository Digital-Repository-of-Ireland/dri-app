# Controller for Digital Objects
#
class ObjectsController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include DRI::Model

  before_filter :authenticate_user!, :only => [:create, :new, :edit, :update]

  # Form for a new dri_data_models model.
  #
  def new
    reset_ingest_state
    @current_step = session[:ingest_step]

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
    if params[:dri_model_audio][:collection_id]
      collection = Collection.find(params[:dri_model_audio][:collection_id])
      @document_fedora.collection = collection
    end
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
    #Merge our object data so far and create the model
    session[:object_params].deep_merge!(params[:dri_model_audio]) if params[:dri_model_audio]
    @document_fedora = DRI::Model::Audio.new(session[:object_params])

    @ingest_methods = get_ingest_methods
    @supported_types = get_supported_types

    # which step am I on? This should be moved to a separate controller so that the
    # objects controller doesn't need to care about steps
    if last_step?
      # Last step, now we should create and save the object
      if params[:dri_model_audio][:collection_id]
        collection = Collection.find(params[:dri_model_audio][:collection_id])
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
      @current_step = session[:ingest_step]
      render :action => :new
    end

  end


  ############### Private methods #############
  # These should be moved to their own module
  private

    def reset_ingest_state
      session[:object_params] = {}
      session[:object_type] = session[:ingest_method] = nil
      session[:ingest_step] = "collection"
    end

    def update_ingest_state
      session[:ingest_method] = params[:ingestmethod] if params[:ingestmethod]
      session[:object_collection] = params[:collection_id] if params[:collection_id]
      session[:object_type] = params[:type] if params[:type]
      session[:ingest_step] = next_ingest_step
    end

    def next_ingest_step
      if session[:ingest_step] == "upload" || session[:ingest_step] == "input"
        session[:ingest_step] = "metadata"
      end
      steps = get_steps
      next_step = steps[steps.index(session[:ingest_step])+1]
      if next_step == "metadata"
        session[:ingest_method]
      else
        next_step
      end
    end

    def myobject
    end

    def last_step?
      steps = get_steps
      if session[:ingest_step] == "upload" || session[:ingest_step] == "input"
        session[:ingest_step] = "metadata"
      end
      session[:ingest_step] == steps.last
    end

   # Returns a list of ingest steps
   def get_steps
     # TODO: these should not really be hardcoded here
     %w[collection ingestmethod type metadata] 
   end

   def get_ingest_methods
      ingest_methods = { "Upload XML" => :upload, "Form entry" => :input }
   end

   def get_supported_types
     supported_types = { "Audio" => :audio }
   end

end

