BlacklightAdvancedSearch::AdvancedSearchBuilder.module_eval do

  def facets_for_advanced_search_form(solr_p)
    return unless search_state.controller.respond_to?(:action_name) && search_state.controller&.action_name == "advanced_search"

    # ensure empty query is all records, to fetch available facets on entire corpus
    solr_p["q"]            = '{!lucene}*:*'
    # explicitly use lucene defType since we are passing a lucene query above (and appears to be required for solr 7)
    solr_p["defType"]      = 'lucene'
    # We only care about facets, we don't need any rows.
    solr_p["rows"]         = "0"

    # Anything set in config as a literal
    if blacklight_config.advanced_search[:form_solr_parameters]
      solr_p.merge!(blacklight_config.advanced_search[:form_solr_parameters])
    end
  end
end
