module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def render_index_doc_actions(document, options = {})
    wrapping_class = options.delete(:wrapping_class) || 'documentFunctions'

    content = []
    content << render(
      partial: 'catalog/bookmark_control',
      locals: { document: document }.merge(options)
    ) if has_user_authentication_provider? && current_or_guest_user
    content_tag('div', content.join("\n").html_safe, class: wrapping_class)
  end

  def render_show_doc_actions(document = @document, options = {})
    content = []
    content << render(
      partial: 'catalog/bookmark_control',
      locals: { document: document }.merge(options)
    ) if has_user_authentication_provider? && current_or_guest_user
    content_tag('div', content.join('\n').html_safe, class: 'documentFunctions')
  end

  def link_to_saved_search(params)
    label = title_to_saved_search(params)
    link_to(raw(label), catalog_index_path(params)).html_safe
  end

  def title_to_saved_search(params)
    params[:mode] = params[:mode].presence || 'objects'
  
    "#{params[:mode].to_s.capitalize} (" + render_search_to_s_q(params) + render_search_to_s_filters(params) + ")"
  end

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  def link_back_to_catalog(opts = { label: nil })
    scope = opts.delete(:route_set) || self
    query_params = current_search_session.try(:query_params) || {}

    if search_session['counter']
      per_page = (search_session['per_page'] || default_per_page).to_i
      counter = search_session['counter'].to_i

      query_params[:per_page] = per_page unless search_session['per_page'].to_i == default_per_page
      query_params[:page] = ((counter - 1) / per_page) + 1
    end

    link_url = if query_params.empty?
                 search_action_path(only_path: true)
               else
                 scope.url_for(query_params)
               end
    label = opts.delete(:label)

    if link_url =~ /bookmarks/
      label ||= t('blacklight.back_to_bookmarks')
    elsif link_url =~ /collections/
      opts[:label] ||= t('blacklight.back_to_collection')
    end

    label ||= t('blacklight.back_to_search')

    link_to label, link_url, opts
  end

  ##
  # Determine whether to render a given field in the show view
  #
  # @param [SolrDocument] document
  # @param [Blacklight::Solr::Configuration::SolrField] solr_field
  # @return [Boolean]
  def should_render_show_field?(document, solr_field)
    if solr_field.field.include?('description')
      field_no_tesim = solr_field.field.gsub('_tesim', '')
      split_fields = field_no_tesim.split(/\s*_\s*/)
      if ISO_639.find(split_fields[-1]).nil?
        if (!document[split_fields.join('_') << '_gle_tesim'].nil?)
          return false
        else
          super(document, solr_field)
        end
      elsif ISO_639.find(split_fields[-1]).include?('eng')
        split_fields.pop
        if !document[split_fields.join('_') << '_gle_tesim'].nil?
          super(document, solr_field)
        else
          return false
        end
      else
        super(document, solr_field)
      end
    else
      super(document, solr_field)
    end
  end
end
