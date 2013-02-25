module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior  

  def render_index_doc_actions(document, options={})
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions"

    content = []
    content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user
    content << render(:partial => 'catalog/collection_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user
    content_tag("div", content.join("\n").html_safe, :class=> wrapping_class)
  end

  def render_show_doc_actions(document=@document, options={})
  wrapping_class = options.delete(:documentFunctions) || "documentFunctions"
  content = []
  content << render(:partial => 'catalog/bookmark_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user
  content << render(:partial => 'catalog/collection_control', :locals => {:document=> document}.merge(options)) if has_user_authentication_provider? and current_or_guest_user

  content_tag("div", content.join("\n").html_safe, :class=>"documentFunctions")
end

end
