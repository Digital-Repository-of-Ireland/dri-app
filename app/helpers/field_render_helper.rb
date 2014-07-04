module FieldRenderHelper

  # Returns the default html field separator characters
  def field_value_separator
    ''
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

    indexed_value = args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    indexed_value = [indexed_value] unless indexed_value.is_a? Array
    indexed_value = indexed_value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}

    last_index = args[:field].rindex('_')
    field = args[:field][0..last_index-1]

    # if (args[:field] and args[:field].match(/_facet$/))
    if (args[:field] and (args[:field][0,5] == "role_" or blacklight_config.facet_fields[ActiveFedora::SolrService.solr_name(field, :facetable)]))
      facet_name = ActiveFedora::SolrService.solr_name(field, :facetable)
      if args[:field][0,5] == "role_"
        facet_name = ActiveFedora::SolrService.solr_name("person", :facetable)
      end
      facet_arg = get_search_arg_from_facet :facet => facet_name

      value = value.each_with_index.map do |v,i|
        "<a href=\"" << url_for({:action => 'index', :controller => 'catalog', facet_arg => standardise_facet(:facet => facet_name, :value => indexed_value[i])}) << "\">" << standardise_value(:facet_name => facet_name, :value => v) << "</a>"
      end
    else
      if value.length > 1
        value = value.each_with_index.map do |v,i|
          '<dd>' << indexed_value[i] << '</dd>'
        end

      end
    end

    return value.join(field_value_separator).html_safe
  end

  # Overriding the render_document_show_field_label helper method to automatically translate field headers.
  def render_document_show_field_label args
    field = args[:field]
    label = blacklight_config.show_fields[field].label

    if label[0, 5] == 'role_'
      html_escape t('dri.vocabulary.marc_relator.'+label[5,3])
    else
      html_escape t('dri.views.fields.'+label)
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

  def standardise_value args

    if args[:facet_name] == "temporal_coverage_sim" || args[:facet_name] == "geographical_coverage_sim"
      return get_value_from_solr_field args[:value], "name"
    else
      return args[:value]
    end

  end

  def render_arbitrary_facet_links(fields)
    url_args = {:action => 'index', :controller => 'catalog'}
    fields.each do |field, value|
      if (blacklight_config.facet_fields[ActiveFedora::SolrService.solr_name(field, :facetable)])
        facet_name = ActiveFedora::SolrService.solr_name(field, :facetable)
        facet_arg = get_search_arg_from_facet :facet => facet_name
        url_args[facet_arg] = value
      end
    end
    url_for(url_args)
  end

  # For form views, returns a list of "people" values in qualifed dublin core that have values.
  # Also sets @qdc_people_select_list, for creating a select list in HTML based on qualified dublin core people
  # fields.
  def qdc_extract_people
    @qdc_people_select_list = [[t('dri.views.metadata.dublin_core'), [[t("dri.views.fields.creator"), "creator"],
                                                                      [t("dri.views.fields.contributor"), "contributor"],
                                                                      [t("dri.views.fields.publisher"), "publisher"]]]]
    qdc_people = Hash.new
    marc_relator_select_list = Array.new

    @qdc_people_select_list[0][1].each do | value |
      array_result = @object.send(value[1])
      if (array_result != nil || array_result.length > 0)
        qdc_people.merge!( value[1] => array_result)
      end
    end

    DRI::Vocabulary.marcRelators.each do |role|
      array_result = @object.send("role_"+role)
      marc_relator_select_list.push [ role + " - " + t("dri.vocabulary.marc_relator."+role), "role_"+role]
      if (array_result != nil || array_result.length > 0)
        qdc_people.merge!( "role_"+role => array_result)
      end
    end

    @qdc_people_select_list.push [ t('dri.vocabulary.name.marc_relators'), marc_relator_select_list]

    qdc_people
  end

  def get_value_from_solr_field solrField, value
    return nil if solrField.blank? or value.blank?

    solrField.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?(value)
        return v
      end
    end
    return solrField
  end

end
