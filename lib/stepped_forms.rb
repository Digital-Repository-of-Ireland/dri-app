module SteppedForms

  # Module with functions for controlling steps in multi-step forms
 
  ############### Private methods #############
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

end  # End Validators module
