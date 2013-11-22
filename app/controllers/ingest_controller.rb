# Controller for Ingesting objects
#

require 'stepped_forms'

class IngestController < CatalogController
  include SteppedForms

  before_filter :authenticate_user!, :only => [:create, :new]

  # Form for a new dri_data_models model.
  #
  def new
    reset_ingest_state
    @current_step = session[:ingest][:current_step]

    respond_to do |format|
      format.html
    end
  end

  # Handles the ingest process using partial forms
  #
  def create
    if !session[:ingest][:object_type].blank?
      @type = session[:ingest][:object_type]
      @object = Batch.new
      @object.object_type = [@type]
      if params[:batch] != nil
        @object.update_attributes params[:batch]
      else
        @object.title = [""]
        @object.description = [""]
        @object.creator = [""]
        @object.rights = [""]
        @object.type = ["Text"]

        if @type == "audio"
          @object.type = ["Sound"]
        elsif @type = "pdfdoc"
          @object.type == ["Text"]
        else
          @object.type = [""]
        end
      end
      
    else
      @object = Batch.new
      @object.object_type = ["Text"]
      if params[:batch] != nil
        @object.update_attributes params[:batch]
      else
        @object.title = [""]
        @object.description = [""]
        @object.creator = [""]
        @object.rights = [""]
        @object.type = ["Text"]
      end
    end

    if !session[:ingest][:collection].blank?
      @collection = session[:ingest][:collection]
    end

    @ingest_methods = get_ingest_methods
    @supported_types = get_supported_types

    # Continue was pressed on a non-final step, increment the current step
    # and update session state
    if valid_step_data?(session[:ingest][:current_step])
      update_ingest_state
    end
    @current_step = session[:ingest][:current_step]
    render :action => :new
  end

end

