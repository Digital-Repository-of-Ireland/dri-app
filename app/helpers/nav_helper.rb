module NavHelper

  WORKSPACE_PATHS = %w(
    /bookmarks
    /user_groups
    /search_history
    /saved_searches
    /ingest/
    /ingest/batch
    /ingest/ingests
    /pages/reports
    /reports
  ).freeze

  def browse_active?
    catalog_active? || organisations_active?
  end

  def workspace_active?
    path = request.path
    if WORKSPACE_PATHS.any? { |p| path.include?(p) } || workspace_controller?
      true
    else
     false
    end
  end

  def workspace_controller?
    %w(my_collections workspace collections objects).include? controller.controller_name
  end

  def catalog_active?
    (controller_name == 'catalog') && (controller.action_name != 'index')  || (request.path.include? "/catalog")
  end

  def organisations_active?
    controller.controller_name == 'institutes' && controller.action_name == 'index'
  end
end
