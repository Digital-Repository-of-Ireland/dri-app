module Blacklight
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to t('blacklight.search.start_over'), start_over_path, class: 'catalog_startOverLink btn btn-primary'
    end

    private

    ##
    # Get the path to the search action with any parameters (e.g. view type)
    # that should be persisted across search sessions.
    def start_over_path query_params = params
      h = {}
      current_index_view_type = query_params['view'] || 'grid'
      h[:view] = current_index_view_type
      h[:mode] = query_params[:mode] if query_params.key?(:mode)

      helpers.search_action_path(h)
    end
  end
end
