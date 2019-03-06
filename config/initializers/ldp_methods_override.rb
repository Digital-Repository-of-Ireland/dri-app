
Ldp::Client::Methods.module_eval do
  def check_for_errors resp
    resp.tap do |resp|
      unless resp.status < 400
        raise case resp.status
          when 400
            if resp.env.method == :head
              # If the request was a HEAD request (which only retrieves HTTP headers),
              # re-run it as a GET in order to retrieve a message body (which is passed on as the error message)
              get(resp.env.url.path)
            else
              Ldp::BadRequest.new(resp.body)
            end
          when 404
            Ldp::NotFound.new(resp.body)
          when 409
            Ldp::Conflict.new(resp.body)
          when 410
            Ldp::Gone.new(resp.body)
          when 412
            Ldp::EtagMismatch.new(resp.body)
          else
            Ldp::HttpError.new("STATUS: #{resp.status} #{resp.body[0, 1000]}...")
          end
      end
    end
  end
end
