module SteppedForms

  # Module with functions for controlling steps in multi-step forms
 
  ############### Private methods #############
  private

    def reset_ingest_state
      session[:object_params] = {}
      session[:ingest] = {}
      session[:ingest] = {:current_step => "collection"}
    end

    def update_ingest_state
      session[:ingest][:method] = params[:ingestmethod] if params[:ingestmethod]
      session[:ingest][:collection] = params[:ingestcollection] if params[:ingestcollection]
      session[:ingest][:type] = params[:ingesttype] if params[:ingesttype]
      session[:ingest][:current_step] = next_ingest_step
    end

    def next_ingest_step
      if session[:ingest][:current_step] == "upload" || session[:ingest][:current_step] == "input"
        session[:ingest][:current_step] = "metadata"
      end
      steps = get_steps
      next_step = steps[steps.index(session[:ingest][:current_step])+1]
      if next_step == "metadata" and session[:ingest][:method].present?
        session[:ingest][:method]
      elsif next_step == "metadata" and session[:ingest][:method].blank?
        # This should not occur
        "ingestmethod"
      elsif next_step == "metadata" and session[:ingest][:type].blank
        # This should not occur
        "type"
      else
        next_step
      end
    end

    def last_step?
      steps = get_steps
      if session[:ingest][:current_step] == "upload" || session[:ingest][:current_step] == "input"
        session[:ingest][:current_step] = "metadata"
      end
      session[:ingest][:current_step] == steps.last
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
     supported_types = { "Audio" => :audio, "Pdf" => :pdfdoc }
   end

end
