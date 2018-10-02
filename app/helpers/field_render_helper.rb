module FieldRenderHelper
  # Returns the default html field separator characters
  def field_value_separator
    ''
  end

  # Helper method to display to toggle the description metadata language
  # @param[SolrDocument] :document
  # @param[SolrField] :field
  #
  def render_description(args)
    path = { path: request.fullpath }
    current_ml = cookies[:metadata_language]
    current_ml = 'all' if current_ml.blank?

    path[:id] = if I18n.locale == :ga
                  'ga'
                else
                  'en'
                end

    if args[:document]['description_gle_tesim']
      if current_ml == 'all' && args[:field] == 'description_gle_tesim'
        path[:metadata_language] = "en"
        return parse_description(args) << (link_to t('dri.views.fields.hide_description_gle'), lang_path(path), class: :dri_toggle_metadata)
      elsif current_ml == 'all' && args[:field] == 'description_eng_tesim'
        path[:metadata_language] = "ga"
        return parse_description(args) << (link_to t('dri.views.fields.hide_description_eng'), lang_path(path), class: :dri_toggle_metadata)
      else
        if current_ml == 'ga' && args[:field] == 'description_gle_tesim'
          path[:metadata_language] = "en"
          return parse_description(args) << (link_to t('dri.views.fields.hide_description_gle'), lang_path(path), class: :dri_toggle_metadata)
        elsif current_ml == 'ga' && args[:field] == 'description_eng_tesim'
          path[:metadata_language] = "all"
          return (link_to t('dri.views.fields.show_description_eng'), lang_path(path), class: :dri_toggle_metadata)
        elsif current_ml == 'en' && args[:field] == 'description_eng_tesim'
          path[:metadata_language] = "ga"
          return parse_description(args) << (link_to t('dri.views.fields.hide_description_eng'), lang_path(path), class: :dri_toggle_metadata)
        elsif current_ml == 'en' && args[:field] == 'description_gle_tesim'
          path[:metadata_language] = "all"
          return (link_to t('dri.views.fields.show_description_gle'), lang_path(path), class: :dri_toggle_metadata)
        else
          parse_description(args)
        end
      end
    else
      parse_description(args)
    end
  end

  # Helper method to display the description field if it contains multiple paragraphs/values
  # @param[SolrDocument] :document
  # @param[SolrField] :field
  # @return array of field values with HTML paragraph mark-up
  #
  def parse_description(args)
    if args[:document][args[:field]].size > 1
      args[:document][args[:field]].collect!.each { |value| simple_format(value)  }
    else
      simple_format(args[:document][args[:field]].first)
    end
  end

  # Overwrites the method located in Blacklight::BlacklightHelperBehavior,
  # allowing DRI to customise how metadata fields are rendered.
  def render_document_show_field_value(args)
    value = args[:value]

    if args[:field] && blacklight_config.show_fields[args[:field]]
      field_config = blacklight_config.show_fields[args[:field]]
      value ||= send(blacklight_config.show_fields[args[:field]][:helper_method], args) if field_config.helper_method
      value ||= args[:document].highlight_field(args[:field]).map { |x| x.html_safe } if field_config.highlight
    end

    value ||= args[:document].get(args[:field], sep: nil) if args[:document] && args[:field]
    value = [value] unless value.is_a?(Array)
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

    indexed_value = args[:document].get(args[:field], sep: nil) if args[:document] && args[:field]
    indexed_value = [indexed_value] unless indexed_value.is_a? Array
    indexed_value = indexed_value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

    field = args[:field].rpartition('_').reject(&:empty?).first if args[:field]

    # if (args[:field] and args[:field].match(/_facet$/))
    if args[:field] && (args[:field][0, 5] == "role_" || blacklight_config.facet_fields[ActiveFedora.index_field_mapper.solr_name(field, :facetable)])
      value = render_facet_link(args, field, value, indexed_value)
    else
      if value.length > 1
        unless field.include?("date")
          value = value.each_with_index.map do |v, i|
            unless uri?(indexed_value[i])
              '<dd>' << indexed_value[i] << '</dd>'
            end
          end
        else
          value = value.each.map do |v|
            '<dd>' << v << '</dd>'
          end
        end
      end
    end

    value.join(field_value_separator).html_safe
  end

  # Overriding the render_document_show_field_label helper method to automatically translate field headers.
  def render_document_show_field_label(args)
    field = args[:field]
    label = blacklight_config.show_fields[field].label

    if label[0, 5] == 'role_'
      html_escape t('vocabulary.marc_relator.codes.' + label[5, 3])
    else
      html_escape t('dri.views.fields.' + label)
    end
  end

  def render_index_field_label(args)
    field = args[:field]
    label = index_fields[field].label

    if label[0, 5] == 'role_'
      html_escape t('vocabulary.marc_relator.codes.' + label[5, 3]) + ":"
    else
      html_escape t('dri.views.fields.' + label) + ":"
    end
  end

  # Used when rendering a faceted link in catalog#show. Determines the blacklight search argument
  # for the resulting catalog#index search.
  def get_search_arg_from_facet(args)
    facet = args[:facet]
    search_arg = "f[" << facet << "][]"

    if (facet[0, 5] == 'role_') || (facet == ActiveFedora.index_field_mapper.solr_name('creator', :facetable)) || (facet == ActiveFedora.index_field_mapper.solr_name('contributor', :facetable))
      search_arg = "f[" << ActiveFedora.index_field_mapper.solr_name('person', :facetable) << "][]"
    end

    search_arg
  end

  # Sometimes in order to provide the most accurate linking between objects, we have to transform a metadata
  # field value into a common standard that the facet index understands. eg. all language codes get converted into
  # ISO 639.2 three-letter codes
  def standardise_facet(args)
    facet = args[:facet]

    standardised = if facet == ActiveFedora.index_field_mapper.solr_name('language', :facetable)
                     DRI::Metadata::Descriptors.standardise_language_code(args[:value]) || args[:value]
                   else
                     args[:value]
                   end

    standardised.mb_chars.downcase
  end

  def standardise_value(args)
    if args[:facet_name] == ActiveFedora.index_field_mapper.solr_name('temporal_coverage', :facetable, type: :string) || args[:facet_name] == ActiveFedora.index_field_mapper.solr_name('geographical_coverage', :facetable, type: :string)
      get_value_from_solr_field(args[:value], "name")
    else
      args[:value]
    end
  end

  def render_arbitrary_facet_links(fields)
    url_args = { action: 'index', controller: 'catalog' }
    fields.each do |field, value|
      next unless blacklight_config.facet_fields[ActiveFedora.index_field_mapper.solr_name(field, :facetable)]

      facet_name = ActiveFedora.index_field_mapper.solr_name(field, :facetable)
      facet_arg = get_search_arg_from_facet(facet: facet_name)
      url_args[facet_arg] = value
    end

    url_for(url_args)
  end

  def render_facet_link(args, field, value, indexed_value)
    facet_name = ActiveFedora.index_field_mapper.solr_name(field, :facetable)
    if args[:field][0, 5] == "role_"
      facet_name = ActiveFedora.index_field_mapper.solr_name("person", :facetable)
    end
    facet_arg = get_search_arg_from_facet(facet: facet_name)

    value.each_with_index.map do |v, i|
      # don't show URLs in the UI
      next if uri?(indexed_value[i])
      standardised_value = standardise_value(facet_name: facet_name, value: v)
      next unless standardised_value

      "<a href=\"" << url_for(
                            {
                              action: 'index',
                              controller: controller_name,
                              facet_arg => standardise_facet(facet: facet_name, value: indexed_value[i])
                            }
                      ) << "\">" << standardised_value << "</a>"
    end
  end


  # For form views, returns a list of "people" values in qualifed dublin core that have values.
  # Also sets @qdc_people_select_list, for creating a select list in HTML based on qualified dublin core people
  # fields.
  def qdc_extract_people
    @qdc_people_select_list = [[t('dri.views.metadata.dublin_core'), [[t("dri.views.fields.contributor"), "contributor"],
                                                                      [t("dri.views.fields.publisher"), "publisher"]]]]

    qdc_people = {}
    marc_relator_select_list = []

    @qdc_people_select_list[0][1].each do |value|
      array_result = @object.send(value[1])
      if !array_result.nil? && !array_result.empty?
        qdc_people.merge!(value[1] => array_result)
      end
    end

    DRI::Vocabulary.marc_relators.each do |role|
      array_result = @object.send("role_" + role)
      marc_relator_select_list.push([role + " - " + t("vocabulary.marc_relator.codes." + role), "role_" + role])
      if !array_result.nil? && !array_result.empty?
        qdc_people.merge!("role_" + role => array_result)
      end
    end

    @qdc_people_select_list.push([t('vocabulary.marc_relator.name'), marc_relator_select_list])

    qdc_people
  end

  def get_value_from_solr_field(solr_field, value)
    return nil if solr_field.blank? || value.blank?

    dcmi_pairs = {}
    solr_field.split(/\s*;\s*/).each do |component|
      (k, v) = component.split(/\s*=\s*/)
      dcmi_pairs[k] = v unless v.nil?
    end

    unless dcmi_pairs.empty?
      return dcmi_pairs[value].presence
    end

    solr_field
  end
end
