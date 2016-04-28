module LinkHelper

  def review_link(text, url, popover_text)
    link_to text, url, { class: "dri_help_popover", "data-content" => popover_text, "data-trigger"=>"hover", "data-placement"=>"left"}
  end

end