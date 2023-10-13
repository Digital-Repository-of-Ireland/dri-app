module LinkHelper
  def review_link(text, url, popover_text)
    link_to text, url, {
      class: "dri_help_popover",
      "data-bs-content" => popover_text,
      "data-bs-trigger" => "hover",
      "data-bs-placement" => "left"
    }
  end
end
