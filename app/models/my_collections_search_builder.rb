# frozen_string_literal: true
class MyCollectionsSearchBuilder < SearchBuilder
  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_workspace_access_controls_to_solr_params]
end
