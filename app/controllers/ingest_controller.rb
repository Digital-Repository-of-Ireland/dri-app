# Controller for Ingesting objects
#

require 'stepped_forms'

class IngestController < CatalogController
  include SteppedForms
  include UserGroup::Helpers

  before_filter :authenticate_user_from_token!, :only => [:create, :new]
  before_filter :authenticate_user!, :only => [:create, :new]

  # Form for a new dri_data_models model.
  #
  def new
    reset_ingest_state
    get_supported_licences()

    @current_step = session[:ingest][:current_step]

    respond_to do |format|
      format.html
    end
  end

  # Handles the ingest process using partial forms
  #
  def create
    get_supported_licences()

    if session[:ingest][:object_type].present?
      @type = session[:ingest][:object_type]
    else
      @type = "Text"
    end

    @object = Batch.new
    @object.object_type = [@type]

    if params[:batch].present?
      @object.update_attributes params[:batch]
    else
      @object.title = [""]
      @object.description = [""]
      @object.creator = [""]
      @object.rights = [""]
      @object.creation_date = [""]
      @object.type = [@type]
    end

    @collection = session[:ingest][:collection] if session[:ingest][:collection].present?

    @ingest_methods = get_ingest_methods
    @supported_types = get_supported_types

    # Continue was pressed on a non-final step, increment the current step
    # and update session state
    update_ingest_state if valid_step_data?(session[:ingest][:current_step])

    @current_step = session[:ingest][:current_step]
    render :action => :new
  end

end

