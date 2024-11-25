# frozen_string_literal: true

# @note Passes current_ability to the search builder.
# We should be able to remove this once Blacklight access controls support version 7.
class SearchService < Blacklight::SearchService
  attr_reader :current_ability

  def initialize(config:, search_state: nil, user_params: nil, search_builder_class: config.search_builder_class, current_ability:, **context)
    @blacklight_config = config
    @search_state = search_state || Blacklight::SearchState.new(user_params || {}, config)
    @user_params = @search_state.params
    @search_builder_class = search_builder_class
    @context = context
    @current_ability = current_ability
  end
end
