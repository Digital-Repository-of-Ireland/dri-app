BrowseEverythingController.class_eval do

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
      self.content_type ||= Mime[:js]
      "#{options[:callback]}(#{json})"
    else
      self.content_type ||= Mime[:json]
      json
    end
  end

  private

  def browser
    url_options = BrowseEverything.config
    if url_options['sandbox_file_system'].present?
        url_options['sandbox_file_system'][:current_user] = current_user.email if current_user
    end

    BrowserFactory.build(session: session, url_options: url_options)
  end
end
