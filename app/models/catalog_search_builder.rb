# frozen_string_literal: true
class CatalogSearchBuilder < SearchBuilder
  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like Assets
  self.default_processor_chain += [:subject_place_filter, :exclude_unwanted_models, :published_models_only, :configure_timeline]

  # Excludes objects from the collections view or collections from the objects view
  def published_models_only(solr_parameters)
    solr_parameters[:fq] << DRI::Catalog::PUBLISHED_ONLY
  end
end
