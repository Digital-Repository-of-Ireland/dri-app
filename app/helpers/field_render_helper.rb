module FieldRenderHelper

  def field_value_separator
    '<br/>'
  end

  # Overwrites the method located in Blacklight::BlacklightHelperBehavior,
  # allowing DRI to customise how metadata fields are rendered.
  def render_document_show_field_value args
    value = args[:value]

    if args[:field] and blacklight_config.show_fields[args[:field]]
      field_config = blacklight_config.show_fields[args[:field]]
      value ||= send(blacklight_config.show_fields[args[:field]][:helper_method], args) if field_config.helper_method
      value ||= args[:document].highlight_field(args[:field]).map { |x| x.html_safe } if field_config.highlight
    end

    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]

    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}
    value = value.map { |v| html_escape v }

    if (args[:field] and args[:field].match(/_facet$/))
      facet_arg = get_search_arg_from_facet :facet => args[:field]
      value = value.map { |v| "<a href=\"" << url_for({:action => 'index', :controller => 'catalog', facet_arg => v}) << "\">" << v << "</a>"}
    end
    return value.join(field_value_separator).html_safe
  end

  # Used when rendering a faceted link in catalog#show. Determines the blacklight search argument
  # for the resulting catalog#index search.
  def get_search_arg_from_facet args
     facet = args[:facet]
     search_arg = "f[" << facet << "][]"

     if ((facet == 'guest_facet') || (facet == 'presenter_facet'))
       search_arg = "f[person_facet][]"
     end

     return search_arg
  end


end
