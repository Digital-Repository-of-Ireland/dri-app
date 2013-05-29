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

  def render_internal_error(exception)
    render_exception(:internal_server_error, t('dri.views.exceptions.internal_error'))
  end

  def render_bad_request(exception)
    render_exception(:bad_request, exception.message)
  end

  def render_access_denied(exception)
    render_exception(:unauthorized, exception.message)
  end

  def render_exception(status_type, message)
    status_message = status_to_message(status_type)

    respond_to do |type|
      type.html { render :template => "errors/error_display",
                         :locals => { :header => status_message,
                                      :message => message }, 
                         :status => status_type}
      type.all  { render :nothing => true, :status => status_type}
    end
    true
  end

  def status_to_message(status)
    HTTP_STATUS_CODES[status_code(status)]
  end
end
