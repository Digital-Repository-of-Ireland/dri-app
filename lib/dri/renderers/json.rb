module DRI::Renderers::Json
  def format_json(json, options)
    unless json.kind_of?(String)
      # return hash representation of model if it supports that
      json = json.as_json(options) if json.respond_to?(:as_json)
      # handle pretty json output for any json response
      if params[:pretty] == 'true'
        json = JSON.pretty_generate(json, options)
      else
        json = json.to_json
      end
    end

    if options[:callback].present?
      self.media_type ||= Mime[:js]
      "#{options[:callback]}(#{json})"
    else
      self.media_type ||= Mime[:json]
      json
    end
  end
end
