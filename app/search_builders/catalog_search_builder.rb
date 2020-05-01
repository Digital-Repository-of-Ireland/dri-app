# frozen_string_literal: true
class CatalogSearchBuilder < SearchBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]

  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like Assets
  self.default_processor_chain += [:published_models_only]

  # Excludes objects from the collections view or collections from the objects view
  def published_models_only(solr_parameters)
    solr_parameters[:fq] << PUBLISHED_ONLY
  end
end
