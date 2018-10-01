module DRI
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

    class NotFound < StandardError
    end

    class InvalidXML < StandardError
    end

    class ValidationErrors < StandardError
    end

    class InstituteError < StandardError
    end

    class ResqueError < StandardError
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

    def render_not_found(exception)
      render_exception(:not_found, exception.message)
    end

    def render_resque_error(exception)
      render_exception(:internal_server_error, t('dri.views.exceptions.resque_error'))
    end

    def render_exception(status_type, message)
      status_message = status_to_message(status_type)

      respond_to do |format|
        format.html do
          render(
            template: 'errors/error_display',
            locals: { header: status_message, message: message },
            status: status_type
          )
        end
        format.json do
          code = "#{status_code(status_type)}"
          render(
            json: { errors: [{ status: code, detail: message }] },
            content_type: 'application/json', 
            status: code 
          )
        end
        format.all  { render nothing: true, status: status_type}
      end
      true
    end

    def render_404(e)
      respond_to do |format|
        format.html  {
          render file: "#{Rails.root}/public/404.html", 
          layout: false, 
          status: 404 
        }
        format.json {
          render json: {errors: [{status: "404", detail: "#{e}"}] }, 
          content_type: 'application/json', status: 404 
        }
      end
    end

    # 401 handled by CustomDeviseFailureApp

    def status_to_message(status)
      HTTP_STATUS_CODES[status_code(status)]
    end
  end
end
