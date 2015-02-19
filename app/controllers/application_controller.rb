require 'exceptions'
require 'permission_methods'
require 'solr/query'

class ApplicationController < ActionController::Base

  before_filter :set_locale, :set_cookie

  include HttpAcceptLanguage

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  # Adds Hydra behaviors into the application controller
  include Hydra::Controller::ControllerBehavior

  include Exceptions

  include UserGroup::PermissionsCheck
  include UserGroup::SolrAccessControls
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

  def set_cookie
    cookies[:accept_cookies] = "yes" if current_user
  end

  def set_access_permissions(key, collection=nil)
    params[key][:master_file] = master_file_permission(params[key].delete(:master_file)) if params[key][:master_file].present?
    if !collection.blank?
      params[key][:private_metadata] = private_metadata_permission('radio_public')
    else
      params[key][:private_metadata] = private_metadata_permission('radio_inherit')
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    main_app.new_user_session_url
  end

  # Retrieves a Fedora Digital Object by ID
  def retrieve_object(id)
    return ActiveFedora::Base.find(id,{:cast => true})
  end

  def retrieve_object!(id)
    objs = ActiveFedora::Base.find(id,{:cast => true})
    raise Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') +" ID: #{id}" if objs.nil?
    return objs
  end

  def duplicates?(object)
    @duplicates = duplicates(object)

    if @duplicates && !@duplicates.empty?
      warning = t('dri.flash.notice.duplicate_object_ingested', :duplicates => @duplicates.map { |o| "'" + o["id"] + "'" }.join(", ").html_safe)
      flash[:alert] = warning
      @warnings = warning
    end
  end

  # Return a list of all supported licences (for populating select dropdowns)
  def supported_licences
    @licences = {}
    Licence.all.each do |licence|
      @licences["#{licence['name']}: #{licence[:description]}"] = licence['name']
    end
  end

  # Gets Metadata Class
  def get_batch_standard_from_param param
    # Metadata Standard Parameter
    case param
      when "qualifieddc"
        :qdc
      # "marc" is a form param, "collection" is xml root, when bulk_ingest
      when "marc", "collection"
        :marc
      else
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

  def duplicates(object)
    unless object.governing_collection.blank?
      collection_id = object.governing_collection.id
      solr_query = "#{Solrizer.solr_name('metadata_md5', :stored_searchable, type: :string)}:\"#{object.metadata_md5}\" AND #{Solrizer.solr_name('is_governed_by', :stored_searchable, type: :symbol)}:\"info:fedora/#{collection_id}\""
      ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "10", :fl => "id").delete_if{|obj| obj["id"] == object.pid}
    end
  end

end
