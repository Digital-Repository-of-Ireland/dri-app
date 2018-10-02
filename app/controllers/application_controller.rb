class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  before_action :authenticate_user_from_token!
  before_action :set_locale, :set_cookie, :set_metadata_language

  include HttpAcceptLanguage
  
  # handles pretty formatting for any json response
  include DRI::Renderers::Json

  ActionController::Renderers.add :json do |json, options|
    format_json(json, options)
  end

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  include DRI::Exceptions

  include UserGroup::PermissionsCheck
  include Hydra::AccessControlsEnforcement
  include UserGroup::Helpers

  layout 'application'

  protect_from_forgery

  rescue_from Hydra::AccessDenied, with: :render_access_denied
  rescue_from DRI::Exceptions::InternalError, with: :render_internal_error
  rescue_from DRI::Exceptions::BadRequest, with: :render_bad_request
  rescue_from DRI::Exceptions::NotFound, with: :render_not_found
  rescue_from DRI::Exceptions::InvalidXML do |exception|
    flash[:error] = t('dri.flash.alert.invalid_xml', error: exception)
    render_bad_request(DRI::Exceptions::BadRequest.new(t('dri.views.exceptions.invalid_metadata')))
  end
  rescue_from DRI::Exceptions::ValidationErrors do |exception|
    flash[:error] = t('dri.flash.error.validation_errors', error: exception)
    render_bad_request(DRI::Exceptions::BadRequest.new(t('dri.views.exceptions.invalid_metadata')))
  end
  rescue_from DRI::Exceptions::ResqueError, with: :render_resque_error
  rescue_from Blacklight::Exceptions::InvalidSolrID, with: :render_404

  def set_locale
    current_lang = http_accept_language.preferred_language_from(Settings.interface.languages)
    if cookies[:lang].nil? && current_user.nil?
      cookies.permanent[:lang] = current_lang || I18n.default_locale
      I18n.locale = cookies[:lang]
    elsif current_user
      if current_user.locale.nil? #This case covers third party users that log in the first time
        current_user.locale = current_lang || I18n.default_locale
        current_user.save
      end

      I18n.locale = current_user.locale
    else
      I18n.locale = cookies[:lang]
    end
  end

  def set_metadata_language
    current_meta_lang = 'all'
    if cookies[:metadata_language].nil?
      cookies.permanent[:metadata_language] = current_meta_lang
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
    ActiveFedora::Base.find(id, cast: true)
  end

  def retrieve_object!(id)
    objs = ActiveFedora::Base.find(id, cast: true)
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{id}" if objs.nil?
    objs
  end

  # Return a list of all supported licences (for populating select dropdowns)
  def supported_licences
    @licences = {}
    Licence.all.each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end
  end

  private

    def after_sign_in_path_for(resource)
      session["user_return_to"] || user_group.profile_path
    end

    def authenticate_user_from_token!
      user_email = params[:user_email].presence
      user       = user_email && User.find_by_email(user_email)
      # Notice how we use Devise.secure_compare to compare the token
      # in the database with the token given in the params, mitigating
      # timing attacks.
      if user && Devise.secure_compare(user.authentication_token, params[:user_token])
        begin
          sign_in user, store: false
        # handles issue where Devise::Mapping.find_scope! fails #1829
        rescue StandardError => e
          sign_in :user, user, store: false
        end
      end
    end

    def authenticate_admin!
      unless current_user && current_user.is_admin?
        flash[:error] = t('dri.views.exceptions.access_denied')
        redirect_to :back
      end
    end

    def authorize_cm!
      unless current_user && (current_user.is_admin? || current_user.is_cm?)
        flash[:error] = t('dri.views.exceptions.access_denied')
        if request.env["HTTP_REFERER"].present?
          redirect_to(:back)
        else
          raise Hydra::AccessDenied.new(t('dri.flash.alert.create_permission'))
        end
      end
    end

    def read_only
      return unless Settings.read_only == true

      respond_to do |format|
        format.json { head status: 503 }
        format.html do
          flash[:error] = t('dri.flash.error.read_only')
          redirect_to :back
        end
      end
    end

    def locked(id)
      docs = ActiveFedora::SolrService.query("id:#{id}")
      obj = SolrDocument.new(docs.first)

      return unless CollectionLock.exists?(collection_id: obj.root_collection_id)

      respond_to do |format|
        format.json { head status: 403 }
        format.html do
          flash[:error] = t('dri.flash.error.locked')
          redirect_to :back
        end
      end
    end
end
