require 'legato'
require 'signet/oauth_2/client'

class CollectionViewsDatatable
  delegate :params, :link_to, to: :@view
  delegate :user_path, to: 'UserGroup::Engine.routes.url_helpers'

  def initialize(view)
    @view = view

    cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
    ENV['SSL_CERT_FILE'] = cert_path

    keypath = Rails.root.join('config','DRIAPI-14b539c1bdde.p12').to_s
    key         = OpenSSL::PKCS12.new(File.read(keypath), 'notasecret').key
    auth_client = Signet::OAuth2::Client.new(
                  token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                  audience: 'https://accounts.google.com/o/oauth2/token',
                  scope: 'https://www.googleapis.com/auth/analytics.readonly',
                  issuer: 'dri-webapp-viewer@driapi-169411.iam.gserviceaccount.com',
                  signing_key: key,
                  sub: 'dri-webapp-viewer@driapi-169411.iam.gserviceaccount.com')

    access_token = auth_client.fetch_access_token!

    oauth_client = OAuth2::Client.new('', '', {
      authorize_url: 'https://accounts.google.com/o/oauth2/auth',
      token_url: 'https://accounts.google.com/o/oauth2/token'
    })

    @token = OAuth2::AccessToken.new(oauth_client, access_token['access_token'], expires_in: access_token['expires_in'])

    @user  = Legato::User.new(@token)

    profile_id = "80821501"
    @profile = Legato::Management::Profile.all(@user).select {|p| p.id == profile_id}.first    
    
  end

  def as_json(options = {})
    {
      recordsTotal: audit.size,
      recordsFiltered: audit.size,
      data: data
    }
  end

private

  def data
    display_on_page.map do |entry|
      [
       entry.pagePath,
       entry.landingpagePath,
       entry.sessions,
       entry.pageviews
      ]
    end
  end

  def audit
    @audit ||= fetch_analytics
  end

  def fetch_analytics
    print "++++++++++++++++++ #{sort_column}"
    if params[:order][:'0'][:column].present?
      analytics = CustomAnalytics.results(@profile, :sort => sort_column).for_collection('1c18df827')
    else 
      analytics = CustomAnalytics.for_collection("1c18df827", @profile)
    end
    analytics.to_a
  end

  def display_on_page 
    Kaminari.paginate_array(fetch_analytics).page(page).per(per_page)
  end 

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[pagePath pageDepth sessions pageviews]
    columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def item_id(entry)
    if entry.item_type == 'UserGroup::User'
        user = UserGroup::User.find(entry.item_id)
        user.nil? ? entry.item_id : link_to(UserGroup::User.find(entry.item_id).to_s, user_path(entry.item_id))
    elsif entry.item_type == 'UserGroup::Membership'
      entry.item_id
    end
  end
end
