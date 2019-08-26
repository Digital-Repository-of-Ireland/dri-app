module ApplicationHelper
  require 'storage/s3_interface'
  require 'uri'

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?
  end

  def iiif_info_url(doc_id, file_id)
    "#{Settings.iiif.server}/#{doc_id}:#{file_id}/info.json"
  end

  def root?
    request.env['PATH_INFO'] == '/' && request.path.nil? && request.query_string.blank?
  end

  def has_browse_params?
    has_search_parameters? || params[:mode].present? || params[:search_field].present? || params[:view].present?
  end

  def has_search_parameters?
    params[:q].present? || params[:f].present? || params[:search_field].present?
  end

  def has_constraint_params?
    # get all blacklight constraint keys
    constraint_keys = %i[f f_inclusive q q_ws] + search_fields_for_advanced_search.symbolize_keys.keys
    constraint_vals = params.select {|k, v| constraint_keys.include?(k.to_sym)}
    # show constaints if at least one constraint param is non-empty and not on advanced search
    !constraint_vals.empty? && controller_name != 'advanced'
  end

  def has_selected_facet_param?(solr_field)
    !params&.[]('selected_facets')&.[](solr_field).nil?
  end

  def should_render_browse_mode_swap?
    # catalog, bookmarks and my_collections need action index and browse params
    # saved searches only need index action
    return false unless action_name == 'index'
    return true if controller_name == 'saved_searches'
    return true if %w(catalog bookmarks my_collections).include?(controller_name) && has_browse_params?
    return false
  end

  # URI Checker
  def uri?(string)
    uri = URI.parse(string)
    %w(http https).include?(uri.scheme)
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end
end
