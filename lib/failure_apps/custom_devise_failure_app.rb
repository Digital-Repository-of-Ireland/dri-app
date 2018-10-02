require "#{Rails.root}/lib/dri/renderers/json"

module FailureApps
  class CustomDeviseFailureApp < Devise::FailureApp
    include DRI::Renderers::Json

    def respond
      if request.format == :json
        json_error_response
      else
        super
      end
    end

    # required to conform to json api error spec
    # http://jsonapi.org/format/#errors
    def json_error_response
      # status must be assigned, ||= will often return 200
      self.status = 401
      self.content_type = "application/json"
      # have to include format_json here because custom error app 
      # doesn't seem to call render json: as normal
      # so pretty param is ignored
      self.response_body = format_json(
        { errors: [{ status: self.status, detail: i18n_message }] },
        {} # options hash normally handled by render block
      )
    end
  end
end
