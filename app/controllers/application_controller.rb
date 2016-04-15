require 'exceptions'
require 'permission_methods'
require 'solr/query'

class ApplicationController < ActionController::Base

  before_filter :authenticate_user_from_token!
  before_filter :set_locale, :set_cookie, :set_metadata_language

  include HttpAcceptLanguage

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  include Exceptions

  include UserGroup::PermissionsCheck
  #include UserGroup::SolrAccessControls
  include Hydra::AccessControlsEnforcement
  include UserGroup::Helpers

  include PermissionMethods

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  layout 'application'

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  rescue_from Exceptions::InternalError, :with => :render_internal_error
  rescue_from Exceptions::BadRequest, :with => :render_bad_request
  rescue_from Hydra::AccessDenied, :with => :render_access_denied
  rescue_from Exceptions::NotFound, :with => :render_not_found
  rescue_from Exceptions::InvalidXML do |exception|
    flash[:error] = t('dri.flash.alert.invalid_xml', :error => exception)
    render_bad_request(Exceptions::BadRequest.new(t('dri.views.exceptions.invalid_metadata')))
  end
  rescue_from Exceptions::ValidationErrors do |exception|
    flash[:error] = t('dri.flash.error.validation_errors', :error => exception)
    render_bad_request(Exceptions::BadRequest.new(t('dri.views.exceptions.invalid_metadata')))
  end
  rescue_from Exceptions::ResqueError, :with => :render_resque_error

  def set_locale
    currentLang = http_accept_language.preferred_language_from(Settings.interface.languages)
    if cookies[:lang].nil? && current_user.nil?
      cookies.permanent[:lang] = currentLang || I18n.default_locale
      I18n.locale = cookies[:lang]
    elsif current_user
      if current_user.locale.nil? #This case covers third party users that log in the first time
        current_user.locale = currentLang || I18n.default_locale
        current_user.save
      end
      I18n.locale = current_user.locale
    else
      I18n.locale = cookies[:lang]
    end
  end

  def set_metadata_language
    currentMetaLang = 'all'
    if cookies[:metadata_language].nil?
      cookies.permanent[:metadata_language] = currentMetaLang
    end
  end

  def set_cookie
    cookies[:accept_cookies] = "yes" if current_user
  end

  def after_sign_out_path_for(resource_or_scope)
    main_app.new_user_session_url
  end

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    return ActiveFedora::Base.find(id, {cast: true})
  end

  def retrieve_object!(id)
    objs = ActiveFedora::Base.find(id, {cast: true})
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') +" ID: #{id}" if objs.nil?
    return objs
  end

  def warn_if_duplicates
    duplicates = actor.find_duplicates
    return if duplicates.blank?

    warning = t('dri.flash.notice.duplicate_object_ingested', :duplicates => duplicates.map { |o| "'" + o["id"] + "'" }.join(", ").html_safe)
    flash[:alert] = warning
    @warnings = warning
  end

  # Return a list of all supported licences (for populating select dropdowns)
  def supported_licences
    @licences = {}
    Licence.all.each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end
  end

  private

  def authenticate_user_from_token!
    user_email = params[:user_email].presence
    user       = user_email && User.find_by_email(user_email)

    # Notice how we use Devise.secure_compare to compare the token
    # in the database with the token given in the params, mitigating
    # timing attacks.
    if user && Devise.secure_compare(user.authentication_token, params[:user_token])
      sign_in user, store: true
    end
  end

  def read_only
    return unless Settings.read_only == true
    
    respond_to do |format|
      format.json {
        head status: 503
      }
      format.html {
        flash[:error] = t('dri.flash.error.read_only')
        redirect_to :back
      }
    end
  end

end
