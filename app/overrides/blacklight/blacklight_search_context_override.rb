Blacklight::SearchContext.module_eval do
  # A list of query parameters that should not be persisted for a search
  def nonpersisted_search_session_params
    [:action, :controller, :commit, :counter, :total, :search_id, :page, :per_page, :view]
  end
end