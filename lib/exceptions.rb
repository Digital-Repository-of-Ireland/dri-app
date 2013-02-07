module Exceptions
  include Rack::Utils

  class BadRequest < StandardError
  end

  def render_bad_request(exception)
    status_message = status_to_message(:bad_request)
    
    respond_to do |type|
      type.html { render :template => "errors/error_display", :locals => { :header => status_message, :exception => exception }, :status => :bad_request }
      type.all  { render :nothing => true, :status => :bad_request }
    end
    true
  end

  def status_to_message(status)
    HTTP_STATUS_CODES[status_code(status)]
  end
end
