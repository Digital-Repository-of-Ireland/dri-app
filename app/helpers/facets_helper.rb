module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  # Used by CatalogController's language facet_field, show_field and index_field
  # to parse a language code into the full name when needed
  # NOTE: Requires Blacklight 4.2.0 for facet_field to work
  def label_language args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_language value)
      end
    else
      results = transform_language args
    end

    return results
  end


  def parse_era args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_era value)
      end
    else
      results = transform_era args
    end

    return results
  end


  def parse_location args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_loc value)
      end
    else
      results = transform_loc args
    end

    return results
  end

  def is_collection args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_is_collection value)
      end
    else
      results = transform_is_collection args
    end

    return results
  end

  def collection_title args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_collection_title value)
      end
    else
      results = transform_collection_title args
    end

    return results
  end

  def transform_collection_title value
    return 'nil' if value == nil

    pid = value

    unless pid.blank?
      solr_query = ActiveFedora::SolrService.construct_query_for_pids([pid])
      docs = ActiveFedora::SolrService.query(solr_query)
    else
      return value
    end

    return 'nil' if docs.empty?

    doc = docs.first

    return doc[Solrizer.solr_name('title', :stored_searchable, type: :string)].first
  end

  def transform_is_collection value
    if value == nil
      return 'nil'
    end

    value.eql?("false") ? t('dri.views.facets.values.no_collections') : t('dri.views.facets.values.collections')
  end


  # parses encoded era values
  def transform_era value
    return 'nil' if value.nil?

    value.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?('name')
        return v
      end
    end
    return value
  end


  # parses encoded location values
  def transform_loc value
    return 'nil' if value.nil?

    value.split(/\s*;\s*/).each do |component|
      (k,v) = component.split(/\s*=\s*/)
      if k.eql?('name')
        return v
      end
    end
    return value
  end

  # Fetches the correct internationalization translation for a given language code
  def transform_language value
    return 'nil' if value == nil

    standard_lang = DRI::Metadata::Descriptors.standardise_language_code value

    if standard_lang != nil
      t('dri.vocabulary.iso_639_2.'+standard_lang)
    else
      value
    end
  end

  def label_permission args
    results = nil

    if args.is_a?(Hash)
      results = Array.new
      value_list = args[:document][args[:field]]

      value_list.each do |value|
        results.push(transform_permission value)
      end
    else
      results = transform_permission args
    end

    return results
  end

  # Used as helper_method in CatalogController's add_facet_field, doesn't seem to get called.
  def transform_permission value
    case value
      when "0"
        return t('dri.views.objects.access_controls.public')
      when "1"
        return t('dri.views.objects.access_controls.private')
      when "-1"
        return t('dri.views.objects.access_controls.inherited')
      else
        return "unknown?"
    end
  end

  # Overwriting this helper so that we can translate facet values
  # Delete this when Blacklight 4.2 is installed
  def render_facet_value(facet_solr_field, item, options ={})
    label = item.label
    facet_config = facet_configuration_for_field(facet_solr_field)
    if facet_config.label == "Language"
      label = label_language label
    elsif facet_config.label == "Metadata Search Access" || facet_config.label == "Master File Access"
      label = label_permission label
    elsif facet_config.label == "Era"
      label = parse_era label
    elsif facet_config.label == "Places"
      label = parse_location label
    elsif facet_config.label == "Collection"
      label = collection_title label
    end
    # (link_to_unless(options[:suppress_link], label, add_facet_params_and_redirect(facet_solr_field, item), :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
    add_facet = add_facet_params_and_redirect(facet_solr_field, item)
    add_facet.delete(:_)
    (link_to_unless(options[:suppress_link], label.html_safe + " (#{render_facet_count(item.hits)})".html_safe, add_facet))
  end


  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display
  def render_facet_count(num)
    content_tag("b", t('blacklight.search.facets.count', :number => num))
  end


  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item)
    #Updated class for Bootstrap Blacklight.

    link_to(render_facet_value(facet_solr_field, item, :suppress_link => true), remove_facet_params(facet_solr_field, item, params), :class=>"selected")
  end

  # Overwriting this helper so that values containing colons are automatically enclosed in double-quoted strings,
  # otherwise SOLR will report an error.
  def facet_value_for_facet_item item
    value = ""

    if item.respond_to? :value
      value = item.value
    else
      value = item
    end

    if (value.include? ":")
      #value = '"'+value+'"'
      value = value.html_safe
    end

    value
  end

end
