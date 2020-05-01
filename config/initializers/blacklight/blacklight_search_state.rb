Blacklight::SearchState.class_eval do
  ##
  # Extension point for downstream applications
  # to provide more interesting routing to
  # documents
  def url_for_document(doc, options = {})
    if respond_to?(:blacklight_config) and
          blacklight_config.show.route and
          (!doc.respond_to?(:to_model) or doc.to_model.is_a? SolrDocument)
      route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)

      if params[:controller] == 'assets' || (params[:controller] == 'objects' && controller.action_name == 'edit')
        route[:controller] = 'my_collections'
      else
       route[:controller] = params[:controller] if route[:controller] == :current
      end
      route
    else
      doc
    end
  end
end
