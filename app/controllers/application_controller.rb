require 'exceptions'

class ApplicationController < ActionController::Base
  before_filter :set_locale, :set_cookie

  include HttpAcceptLanguage

  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  

  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior

  include Exceptions

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery

  rescue_from Exceptions::BadRequest, :with => :render_bad_request

  def set_locale
    if current_user
      I18n.locale = current_user.locale
    else
      I18n.locale = preferred_language_from(Settings.interface.languages)
    end
    I18n.locale = I18n.default_locale if I18n.locale.blank?
  end

  def set_cookie
    cookies[:accept_cookies] = "yes" if current_user
  end

end
