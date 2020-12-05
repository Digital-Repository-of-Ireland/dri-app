require 'legato'
require 'signet/oauth_2/client'

class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    unless signed_in? && authorized_user?
      flash[:error] = t('dri.flash.error.manager_user_permission')
      return
    end

    @startdate = params[:startdate] || Date.today.at_beginning_of_month
    @enddate = params[:enddate] || Date.today

    respond_to do |format|
      format.html
      format.json do
        render json: AnalyticsCollectionsDatatable.new(profile, view_context)
      end
    end
  end

  def show
    unless signed_in? && authorized_user?
      flash[:error] = t('dri.flash.error.manager_user_permission')
      return
    end

    @startdate = params[:startdate] || Date.today.at_beginning_of_month
    @enddate = params[:enddate] || Date.today

    @document = SolrDocument.find(params[:id])
    raise DRI::Exceptions::BadRequest, t('dri.views.exceptions.unknown_object') + " ID: #{params[:id]}" if @document.nil?

    @file_display_type_count = @document.file_display_type_count(published_only: true)

    respond_to do |format|
      format.html
      format.json do
        render json: AnalyticsCollectionDatatable.new(profile, view_context)
      end
    end
  end

  private

    def authorized_user?
      current_user.is_admin? || current_user.is_om? || current_user.is_cm?
    end

    def profile
      @profile ||= create_profile
    end

    def create_profile
      key         = OpenSSL::PKCS12.new(File.read(Settings.analytics.keyfile), Settings.analytics.secret).key
      auth_client = Signet::OAuth2::Client.new(
                  token_credential_uri: Settings.analytics.token_credential_uri,
                  audience: Settings.analytics.audience,
                  scope: Settings.analytics.scope,
                  issuer: Settings.analytics.issuer,
                  signing_key: key,
                  sub: Settings.analytics.sub)

      access_token = auth_client.fetch_access_token!

      oauth_client = OAuth2::Client.new('', '', {
        authorize_url: 'https://accounts.google.com/o/oauth2/auth',
        token_url: 'https://accounts.google.com/o/oauth2/token'
      })

      token = OAuth2::AccessToken.new(oauth_client, access_token['access_token'], expires_in: access_token['expires_in'])
      user  = Legato::User.new(token)
      Legato::Management::Profile.all(user).select {|p| p.id == Settings.analytics.profile_id}.first
    end
end
