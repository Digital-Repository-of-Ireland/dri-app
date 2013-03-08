# Controller for Ingesting objects
#

require 'stepped_forms'

class IngestController < AssetsController
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
    if !session[:ingest][:type].blank?
      @type = session[:ingest][:type]
      @document_fedora = DRI::Model::DigitalObject.construct(session[:ingest][:type].to_sym, params[:dri_model])
    else
      @document_fedora = DRI::Model::DigitalObject.construct(:audio, params[:dri_model])
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

