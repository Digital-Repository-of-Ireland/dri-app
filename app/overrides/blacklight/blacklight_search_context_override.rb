Blacklight::SearchContext.module_eval do

  def find_or_initialize_search_session_from_params params
    return unless blacklight_config.track_search_session.storage == 'server'

    params_copy = params.reject { |k, v| nonpersisted_search_session_params.include?(k.to_sym) || v.blank? }

    return if params_copy.reject { |k, _v| [:action, :controller, :mode].include? k.to_sym }.blank?

    saved_search = searches_from_history.find { |x| x.query_params == params_copy }

    saved_search || Search.create(query_params: params_copy).tap do |s|
      add_to_search_history(s)
    end
  end

  # A list of query parameters that should not be persisted for a search
  def nonpersisted_search_session_params
    [:commit, :counter, :total, :search_id, :page, :per_page, :view]
  end

end