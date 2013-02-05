class ApplicationController < ActionController::Base
  before_filter :set_locale
 
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  

  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery


  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
