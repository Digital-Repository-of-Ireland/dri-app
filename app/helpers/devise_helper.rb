module DeviseHelper
  # A simple way to show error messages for the current devise resource. If you need
  # to customize this method, you can either overwrite it in your application helpers or
  # copy the views to your application.
  #
  # This method is intended to stay simple and it is unlikely that we are going to change
  # it to add more behavior or options.
  #
  # Overridden in DRI to use flash messages for consistency with the rest of the application
  #
  def devise_error_messages!

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      :count => resource.errors.count,
                      :resource => resource.class.model_name.human.downcase)

   errortext = sentence + "<ul>#{messages}</ul>"

   flash.now[:error] = errortext.html_safe

   return ""

  end
end
