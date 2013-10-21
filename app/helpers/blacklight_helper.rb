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

end
