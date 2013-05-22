module Exceptions
  include Rack::Utils


  class BadRequest < StandardError
  end


  class InternalError < StandardError
  end


  class UnknownMimeType < StandardError
  end


  class WrongExtension < StandardError
  end


  class InappropriateFileType < StandardError
  end

  class BadCommand < StandardError
  end

  class VirusDetected < StandardError
  end

  def render_bad_request(exception)
    status_message = status_to_message(:bad_request)
    
    respond_to do |type|
      type.html { render :template => "errors/error_display", 
                         :locals => { :header => status_message, 
                                      :exception => exception }, 
                         :status => :bad_request }
      type.all  { render :nothing => true, :status => :bad_request }
    end
    true
  end


  def render_internal_error(exception)
    status_message = status_to_message(:internal_server_error)

    respond_to do |type|
      type.html { render :template => "errors/private_error_display",
                         :locals => { :header => status_message,
                                      :message => t('dri.views.exceptions.internal_error') }, 
                         :status => :internal_server_error }
      type.all  { render :nothing => true, :status => :internal_server_error}
    end
    true
  end

  def status_to_message(status)
    HTTP_STATUS_CODES[status_code(status)]
  end
end
