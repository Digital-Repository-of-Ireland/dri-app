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


  # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>nil})
    query_params = session[:search] ? session[:search].dup : {}
    return if query_params.blank?
    query_params.delete :counter
    query_params.delete :total
    link_url = url_for(query_params)
    if link_url =~ /bookmarks/
      opts[:label] ||= t('blacklight.back_to_bookmarks')
    elsif link_url =~ /collections/
      opts[:label] ||= t('blacklight.back_to_collection')
    end

    opts[:label] ||= t('blacklight.back_to_search')

    link_to opts[:label], link_url
  end

end
