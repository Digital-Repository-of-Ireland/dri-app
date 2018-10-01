module FailureApps
  class CustomDeviseFailureApp < Devise::FailureApp
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
      self.status = 401
      self.content_type = "application/json"
      self.response_body = { 
        errors: [{ status: self.status, detail: i18n_message }] 
        }.to_json
    end
  end
end
