module FieldRenderHelper

  # Returns the default html field separator characters
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

    indexed_value = args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    indexed_value = [indexed_value] unless indexed_value.is_a? Array
    indexed_value = indexed_value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}
    indexed_value = indexed_value.map { |v| html_escape v }

    last_index = args[:field].rindex('_')
    field = args[:field][0..last_index-1]

    # if (args[:field] and args[:field].match(/_facet$/))
    if (args[:field] and (args[:field][0,5] == "role_" or blacklight_config.facet_fields[ActiveFedora::SolrService.solr_name(field, :facetable)]))
      facet_name = ActiveFedora::SolrService.solr_name(field, :facetable)
      if args[:field][0,5] == "role_"
        facet_name = ActiveFedora::SolrService.solr_name("person", :facetable)
      end
      facet_arg = get_search_arg_from_facet :facet => facet_name

      value = value.each_with_index.map { |v,i| "<a href=\"" << url_for({:action => 'index', :controller => 'catalog', facet_arg => standardise_facet(:facet => facet_name, :value => indexed_value[i])}) << "\">" << v << "</a>"}
    end
    return value.join(field_value_separator).html_safe
  end

  # Overriding the render_document_show_field_label helper method to automatically translate field headers.
  def render_document_show_field_label args
    field = args[:field]
    label = blacklight_config.show_fields[field].label

    if label[0, 5] == 'role_'
      html_escape t('dri.vocabulary.marc_relator.'+label[5,3])+":"
    else
      html_escape t('dri.views.fields.'+label)+":"
    end
  end

  def render_index_field_label args
    field = args[:field]
    label = index_fields[field].label

    if label[0, 5] == 'role_'
      html_escape t('dri.vocabulary.marc_relator.'+label[5,3])+":"
    else
      html_escape t('dri.views.fields.'+label)+":"
    end
  end

  # Used when rendering a faceted link in catalog#show. Determines the blacklight search argument
  # for the resulting catalog#index search.
  def get_search_arg_from_facet args
     facet = args[:facet]
     search_arg = "f[" << facet << "][]"

     if ((facet[0, 5] == 'role_') || (facet == ActiveFedora::SolrService.solr_name('creator', :facetable)) || (facet == ActiveFedora::SolrService.solr_name('contributor', :facetable)))
       search_arg = "f[" << ActiveFedora::SolrService.solr_name('person', :facetable) << "][]"
     end

     return search_arg
  end

  # Sometimes in order to provide the most accurate linking between objects, we have to transform a metadata
  # field value into a common standard that the facet index understands. eg. all language codes get converted into
  # ISO 639.2 three-letter codes
  def standardise_facet args
    facet = args[:facet]

    if (facet == ActiveFedora::SolrService.solr_name('language', :facetable))
      DRI::Metadata::Descriptors.standardise_language_code args[:value]
    else
      args[:value]
    end
  end

end
