module DRI::Renderers::Json
  def format_json(json, options)
    unless json.kind_of?(String)
      # return hash representation of model if it supports that
      json = json.as_json(options) if json.respond_to?(:as_json)
      # handle pretty json output for any json presonse
      if params[:pretty] == 'true'
        json = JSON.pretty_generate(json, options)
      else
        json = json.to_json
      end
    end

    if options[:callback].present?
      self.content_type ||= Mime::JS
      "#{options[:callback]}(#{json})"
    else
      self.content_type ||= Mime::JSON
      json
    end
  end
end
