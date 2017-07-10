
Blacklight::Bookmarks.module_eval do
  def verify_user
    unless current_or_guest_user or (action_name == "index" and token_or_current_or_guest_user)
      flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied
    end
  end
end
