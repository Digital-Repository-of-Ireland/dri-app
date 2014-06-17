module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def render_index_doc_actions(document, options={})
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions"

    content = []
    content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user
    content_tag("div", content.join("\n").html_safe, :class=> wrapping_class)
  end

  def render_show_doc_actions(document=@document, options={})
    wrapping_class = options.delete(:documentFunctions) || "documentFunctions"
    content = []
    content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user
    content_tag("div", content.join("\n").html_safe, :class=>"documentFunctions")
  end

  def permissons_renderer args
    #permission = args[:document][args[:field]]
    #case permission
    #when 0
    #  return "public"
    #when 1
    #  return "private"
    #when -1
    #  return "inherited"
    #else
    #  return "unknown?"
    #end
    "huh?"
  end

  def link_to_saved_search(params)
    label = "#{params[:mode].to_s.capitalize} (" + render_search_to_s_q(params) + render_search_to_s_filters(params) + ")"
    link_to(raw(label), catalog_index_path(params)).html_safe
  end

  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  def link_back_to_catalog(opts={:label=>nil})
    scope = opts.delete(:route_set) || self
    query_params = current_search_session.try(:query_params) || {}
    return if query_params.blank?
    link_url = scope.url_for(query_params)
    label = opts.delete(:label)

    if link_url =~ /bookmarks/
      label ||= t('blacklight.back_to_bookmarks')
    elsif link_url =~ /collections/
      opts[:label] ||= t('blacklight.back_to_collection')
    end

    label ||= t('blacklight.back_to_search')

    link_to label, link_url, opts
  end

end
