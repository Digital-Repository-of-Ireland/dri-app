module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  DCMI_KEYS = %w(elevation northlimit eastlimit southlimit westlimit uplimit downlimit units zunits projection north east)

  # Used by CatalogController's language facet_field, show_field and index_field
  # to parse a language code into the full name when needed
  # NOTE: Requires Blacklight 4.2.0 for facet_field to work
  def label_language(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_language(value))
      end
    else
      results = transform_language(args)
    end

    results
  end

  def parse_era(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_era(value))
      end
    else
      results = transform_era(args)
    end

    results
  end

  def parse_location(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each { |value| results.push(transform_loc(value)) }
    else
      results = transform_loc(args)
    end

    results
  end

  def is_collection(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_is_collection(value))
      end
    else
      results = transform_is_collection(args)
    end

    results
  end

  def collection_title(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each { |value| results.push(transform_collection_title(value)) }
    else
      results = transform_collection_title(args)
    end

    results
  end

  def transform_collection_title(value)
    return 'nil' if value.nil?

    pid = value
    return value if pid.blank?

    solr_query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([pid])
    docs = ActiveFedora::SolrService.query(solr_query)

    return 'nil' if docs.empty?

    doc = docs.first
    doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)].first
  end

  def transform_is_collection(value)
    return 'nil' if value.nil?

    value == 'false' ? t('dri.views.facets.values.no_collections') : t('dri.views.facets.values.collections')
  end

  # parses encoded era values
  def transform_era(value)
    return 'nil' if value.nil?

    value.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?('name')
        return v unless v.nil? || v.empty?
      end
    end
    value
  end

  # parses encoded location values
  def transform_loc(value)
    return 'nil' if value.nil?

    value.split(/\s*;\s*/).each do |component|
      (k, v) = component.split(/\s*=\s*/)
      dcmi = true if DCMI_KEYS.include?(k)

      if k.eql?('name')
        return v unless v.nil? || v.empty?
      end

      # if DCMI encoding but no name, do not include in facets
      return 'nil' if dcmi
    end
    value
  end

  # Fetches the correct internationalization translation for a given language code
  def transform_language(value)
    return 'nil' if value.nil?

    standard_lang = DRI::Metadata::Descriptors.standardise_language_code(value)

    unless standard_lang.nil?
      t('dri.vocabulary.iso_639_2.' + standard_lang)
    else
      value
    end
  end

  def label_permission(args)
    results = nil

    if args.is_a?(Hash)
      results = []
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_permission(value))
      end
    else
      results = transform_permission(args)
    end

    results
  end

  # Used as helper_method in CatalogController's add_facet_field, doesn't seem to get called.
  def transform_permission(value)
    case value
    when 'public'
      t('dri.views.objects.access_controls.public')
    when 'private'
      t('dri.views.objects.access_controls.private')
    when 'inherit'
      t('dri.views.objects.access_controls.inherited')
    else
      'unknown?'
    end
  end

  ##
  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::SolrResponse::Facets::FacetField]
  # @param [String] facet item
  # @param [Hash] options
  # @option options [Boolean] :suppress_link display the facet, but don't link to it
  # @return [String]
  def render_facet_value(facet_solr_field, item, options = {})
    return if uri?(item.value)
    
    display_value = facet_display_value(facet_solr_field, item)
    return if display_value == 'nil'

    path = search_action_path(add_facet_params_and_redirect(facet_solr_field, item))
    link_to_unless(
      options[:suppress_link],
      display_value.titleize + " (#{item.hits})",
      path, class: 'facet_select'
    )
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display
  def render_facet_count(num)
    content_tag('b', t('blacklight.search.facets.count', number: num))
  end

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item)
    # Updated class for Bootstrap Blacklight.
    link_to(
      render_facet_value(facet_solr_field, item, suppress_link: true) + content_tag(:i,'', class: 'fa fa-remove'), 
      remove_facet_params(facet_solr_field, item, params),
      class: 'selected'
    )
  end

  # Overwriting this helper so that values containing colons are automatically enclosed in double-quoted strings,
  # otherwise SOLR will report an error.
  def facet_value_for_facet_item(item)
    value = item.respond_to?(:value) ? item.value : item
    value = value.html_safe if (value.include? ":")

    value
  end
end
