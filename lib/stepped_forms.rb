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
      Settings.ingest.steps
    end

    def get_step_data(step)
      Kernel.eval "Settings.ingest.step_data.#{step}"
    end

    def get_ingest_methods
       ingest_methods = { "Upload XML" => :upload, "Form entry" => :input }
    end

    def get_supported_types
      supported_types = [ "Sound", "Text", "Image", "MovingImage" ]
    end

    def valid_step_data?(step)
      stepdata = get_step_data(step)
      stepdata.each do |dataitem|
        return false unless params[dataitem.to_sym]
      end
    end

end
