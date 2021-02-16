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
    current_ml = cookies[:metadata_language].blank? ? 'all' : cookies[:metadata_language]

    path[:id] = I18n.locale == :ga ? 'ga' : 'en'

    solr_field = args[:field]
    description = args[:document][solr_field]

    return parse_description(description) unless args[:document]['description_gle_tesim']
    if current_ml == 'all'
      lang_code = gle_description?(solr_field) ? 'gle' : 'eng'
      path[:metadata_language] = lang_code == 'gle' ? 'en' : 'ga'
      return parse_description(description) << render_toggle_link(lang_code, path, 'hide')
    else
      return parse_description(description) unless ['ga','en'].include?(current_ml)


      if current_ml == 'ga'
        if gle_description?(solr_field)
          path[:metadata_language] = 'en'
          return parse_description(description) << render_toggle_link('gle', path, 'hide')
        elsif eng_description?(solr_field)
          path[:metadata_language] = 'all'
          return render_toggle_link('eng', path, 'show')
        end
      elsif current_ml == 'en'
        if eng_description?(solr_field)
          path[:metadata_language] = 'ga'
          return parse_description(description) << render_toggle_link('eng', path, 'hide')
        elsif gle_description?(solr_field)
          path[:metadata_language] = 'all'
          return render_toggle_link('gle', path, 'show')
        end
      end
    end
  end

  def gle_description?(field)
    field == 'description_gle_tesim'
  end

  def eng_description?(field)
    field == 'description_eng_tesim'
  end

  def render_toggle_link(lang, path, type)
    link_to(
      t("dri.views.fields.#{type}_description_#{lang}"),
      lang_path(path), class: :dri_toggle_metadata
    )
  end

  # Helper method to display the description field if it contains multiple paragraphs/values
  # @param[SolrDocument] :document
  # @param[SolrField] :field
  # @return array of field values with HTML paragraph mark-up
  #
  def parse_description(description)
    if description.size > 1
      description.collect!.each { |value| simple_format(value)  }
    else
      simple_format(description.first)
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

    value ||= args[:document].fetch(args[:field], sep: nil) if args[:document] && args[:field]
    value = [value] unless value.is_a?(Array)
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

    indexed_value = args[:document].fetch(args[:field], sep: nil) if args[:document] && args[:field]
    indexed_value = [indexed_value] unless indexed_value.is_a? Array
    indexed_value = indexed_value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

    field = args[:field].rpartition('_').reject(&:empty?).first if args[:field]

    if args[:field] && (role_field?(args[:field]) || facet?(field))
      value = render_facet_link(args, field, value, indexed_value)
    else
      value = render_list(field, value, indexed_value) if value.length > 1
    end

    value.join(field_value_separator).html_safe
  end

  def render_list(field, value, indexed_value)
    unless field.include?("date")
      value.each_with_index.map do |v, i|
        '<dd>' << indexed_value[i] << '</dd>'
      end
    else
      value.each.map do |v|
        '<dd>' << v << '</dd>'
      end
    end
  end

  # Overriding the render_document_show_field_label helper method to automatically translate field headers.
  def render_document_show_field_label(args)
    field = args[:field]
    label = blacklight_config.show_fields[field].label

    if role_field?(label)
      html_escape t('vocabulary.marc_relator.codes.' + label[5, 3])
    else
      html_escape t('dri.views.fields.' + label)
    end
  end

  def render_index_field_label(args)
    field = args[:field]
    label = index_fields[field].label

    if role_field?(label)
      html_escape t('vocabulary.marc_relator.codes.' + label[5, 3]) + ":"
    else
      html_escape t('dri.views.fields.' + label) + ":"
    end
  end

  # Used when rendering a faceted link in catalog#show. Determines the blacklight search argument
  # for the resulting catalog#index search.
  def search_arg_from_facet(args)
    facet = args[:facet]
    search_arg = "f[" << facet << "][]"

    if person_facet?(facet)
      search_arg = "f[" << Solrizer.solr_name('person', :facetable) << "][]"
    end

    search_arg
  end

  # Sometimes in order to provide the most accurate linking between objects, we have to transform a metadata
  # field value into a common standard that the facet index understands. eg. all language codes get converted into
  # ISO 639.2 three-letter codes
  def standardise_facet(args)
    facet = args[:facet]

    standardised = if facet == Solrizer.solr_name('language', :facetable)
                     DRI::Metadata::Descriptors.standardise_language_code(args[:value]) || args[:value]
                   else
                     args[:value]
                   end

    standardised.mb_chars.downcase
  end

  def standardise_value(args)
    if [Solrizer.solr_name('temporal_coverage', :facetable, type: :string),
        Solrizer.solr_name('geographical_coverage', :facetable, type: :string)
       ].include?(args[:facet_name])
      value_from_solr_field(args[:value], "name")
    else
      args[:value]
    end
  end

  def render_arbitrary_facet_links(fields)
    url_args = { action: 'index', controller: 'catalog' }
    fields.each do |field, value|
      next unless facet?(field)

      facet_name = Solrizer.solr_name(field, :facetable)
      facet_arg = search_arg_from_facet(facet: facet_name)
      url_args[facet_arg] = value
    end

    url_for(url_args)
  end

  def facet?(field)
    blacklight_config.facet_fields.key?(Solrizer.solr_name(field, :facetable))
  end

  def person_facet?(facet)
    (
      role_field?(facet)) ||
      (facet == Solrizer.solr_name('creator', :facetable)) ||
      (facet == Solrizer.solr_name('contributor', :facetable)
    )
  end

  def role_field?(field)
    field[0, 5] == "role_"
  end

  def render_facet_link(args, field, value, indexed_value)
    facet_name = Solrizer.solr_name(field, :facetable)
    if role_field?(args[:field])
      facet_name = Solrizer.solr_name("person", :facetable)
    end
    facet_arg = search_arg_from_facet(facet: facet_name)

    value.each_with_index.map do |v, i|
      # don't show simple URLs in the UI
      next if uri?(v.gsub('name=', ''))

      standardised_value = standardise_value(facet_name: facet_name, value: v)
      next unless standardised_value

      authority = value_from_solr_field(indexed_value[i], "authority")
      identifier = value_from_solr_field(indexed_value[i], "identifier")

      # for orcids include a repository search on name and the orcid link
      if authority.present? && authority.casecmp("ORCID") && uri?(identifier)
        render_orcid(facet_arg, facet_name, standardised_value, identifier)
      else
        render_link(facet_arg, facet_name, indexed_value[i], standardised_value)
      end
    end
  end

  def render_link(facet_arg, facet_name, indexed_value, standardised_value)
    "<a href=\"" << url_for(
                            {
                              action: 'index',
                              controller: controller_name,
                              facet_arg => standardise_facet(facet: facet_name, value: indexed_value)
                            }
                      ) << "\">" << standardised_value << "</a>"
  end

  def render_orcid(facet_arg, facet_name, standardised_value, identifier)
    "<span class=\"orcid\"><a href=\"" << url_for(
                            {
                              action: 'index',
                              controller: controller_name,
                              facet_arg => standardise_facet(facet: facet_name, value: standardised_value)
                            }
                      ) << "\">" << standardised_value << "</a><a href=\"" << identifier << "\" target=\"_blank\">" << identifier << "</a></span>"
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
      if !array_result.blank?
        qdc_people.merge!(value[1] => array_result)
      end
    end

    DRI::Vocabulary.marc_relators.each do |role|
      array_result = @object.send("role_" + role)
      marc_relator_select_list.push([role + " - " + t("vocabulary.marc_relator.codes." + role), "role_" + role])
      if !array_result.blank?
        qdc_people.merge!("role_" + role => array_result)
      end
    end

    @qdc_people_select_list.push([t('vocabulary.marc_relator.name'), marc_relator_select_list])

    qdc_people
  end

  def value_from_solr_field(solr_field, value)
    return nil if solr_field.blank? || value.blank?

    dcmi_pairs = {}
    solr_field.split(/\s*;\s*/).each do |component|
      (k, v) = component.split(/\s*=\s*/)
      dcmi_pairs[k.downcase] = v unless v.nil?
    end

    return dcmi_pairs[value].presence unless dcmi_pairs.empty?

    solr_field
  end
end
