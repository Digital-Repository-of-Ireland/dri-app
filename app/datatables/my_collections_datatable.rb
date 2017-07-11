require 'legato'
require 'signet/oauth_2/client'

class MyCollectionsDatatable
  delegate :current_user, :params, :link_to, to: :@view
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

    profile_id = "80821501" #TODO: should not be hardcoded!
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
       entry.dimension1,
       entry.users,
      ]
    end
  end

  def audit
    @audit ||= fetch_analytics
  end

  # Get collections for which we have manage permissions
  # TODO consider admin
  # if none then just return empty array
  # else get analytics for these collection ids and return analytics
  def fetch_analytics
    collections = get_collections()
    return collections if collections.empty?

    # get collection names
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(collections)
    object_docs = ActiveFedora::SolrService.query(query,
                  :'fl' => "id, #{ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)}" )
    collection_hash = {}
    object_docs.map { |o| collection_hash[o["id"]] = o["#{ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)}"].first }

    @startdate = params[:startdate] || Date.today.at_beginning_of_month()
    @enddate = params[:enddate] || Date.today


    analytics = CollectionStats.results(@profile, :start_date => @startdate, :end_date => @enddate, :sort => sort_column).collections(*collections).to_a

    analytics.each do |a|
      a.dimension1 = collection_hash[a.dimension1]
    end

    return analytics

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
    columns = %w[dimension1 users]
    columns[params[:order][:'0'][:column].to_i]
    if params[:order][:'0'][:dir].eql?("desc")
      return "-"+columns[params[:order][:'0'][:column].to_i] 
    else
      return columns[params[:order][:'0'][:column].to_i]
    end
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def start
    params[:start]
  end

  def end
    params[:end]
  end

  def item_id(entry)
    if entry.item_type == 'UserGroup::User'
        user = UserGroup::User.find(entry.item_id)
        user.nil? ? entry.item_id : link_to(UserGroup::User.find(entry.item_id).to_s, user_path(entry.item_id))
    elsif entry.item_type == 'UserGroup::Membership'
      entry.item_id
    end
  end

  def get_collections()
    collections = []

    query = "#{ActiveFedora.index_field_mapper.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{current_user.email}"
    solr_query = Solr::Query.new(
      query,
      100,
      { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
    )

    while solr_query.has_more?
      objects = solr_query.pop
      objects.each do |object|
        collections.push(object['id'])
      end
    end

    return collections
  end
    
end
