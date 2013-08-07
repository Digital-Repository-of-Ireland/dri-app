require 'exceptions'

class ApplicationController < ActionController::Base
  before_filter :set_locale, :set_cookie, :authenticate_user!

  include DRI::Metadata
  include DRI::Model

  include HttpAcceptLanguage

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  include Exceptions

  include UserGroup::PermissionsCheck

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  layout 'blacklight'

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  rescue_from Exceptions::InternalError, :with => :render_internal_error
  rescue_from Exceptions::BadRequest, :with => :render_bad_request
  rescue_from Hydra::AccessDenied, :with => :render_access_denied
  rescue_from Exceptions::NotFound, :with => :render_not_found

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


  def after_sign_out_path_for(resource_or_scope)
    main_app.new_user_session_url
  end

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    return objs = ActiveFedora::Base.find(id,{:cast => true})
  end

  def retrieve_object!(id)
    objs = ActiveFedora::Base.find(id,{:cast => true})
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') +" ID: #{id}" if objs.nil?
    return objs
  end

  def check_for_duplicates(object)
      @duplicates = duplicates(object)

      if @duplicates && !@duplicates.empty?
        warning = t('dri.flash.notice.duplicate_object_ingested', :duplicates => @duplicates.map { |o| "'" + o.id + "'" }.join(", ").html_safe)
        flash[:alert] = warning
        @warnings = warning
      end
  end

  private

  def duplicates(object)
    if object.governing_collection && !object.governing_collection.nil?
      ActiveFedora::Base.find(:is_governed_by_ssim => "info:fedora/#{object.governing_collection.id}", :metadata_md5_tesim => object.metadata_md5).delete_if{|obj| obj.id == object.pid}
    end
  end

end
