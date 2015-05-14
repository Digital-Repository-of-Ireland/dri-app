module ConstraintsHelper
  include Blacklight::RenderConstraintsHelperBehavior

  ##
  # OVERRIDEN. Render a single facet's constraint
  #
  # @param [String] facet field
  # @param [Array<String>] selected facet values
  # @param [Hash] query parameters
  # @return [String]
  def render_filter_element(facet, values, localized_params)
    # Overrride BL's render_filter_element
    # When creating remove filter links exclude the date range added parameters, if present
    # Otherwise the filter gets removed but the parameters stay in the URL
    if (facet == "sdateRange")
      excluded_params = [:c_date, :p_date, :s_date, :year_from, :year_to]
      new_localized_params = localized_params.clone
      new_localized_params.except!(*excluded_params)

      super(facet, values, new_localized_params)
    else
      super(facet, values, localized_params)
    end
  end

end