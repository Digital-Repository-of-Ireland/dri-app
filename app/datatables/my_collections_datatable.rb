require 'legato'
require 'signet/oauth_2/client'

class MyCollectionsDatatable
  delegate :current_user, :params, :analytic_path, :link_to, to: :@view
  delegate :user_path, to: 'UserGroup::Engine.routes.url_helpers'

  def initialize(view)
    @view = view

    cert_path = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
    ENV['SSL_CERT_FILE'] = cert_path

    keypath = Rails.root.join('config',Settings.analytics.keyfile).to_s
    key         = OpenSSL::PKCS12.new(File.read(keypath), Settings.analytics.secret).key
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

    @token = OAuth2::AccessToken.new(oauth_client, access_token['access_token'], expires_in: access_token['expires_in'])

    @user  = Legato::User.new(@token)

    @profile = Legato::Management::Profile.all(@user).select {|p| p.id == Settings.analytics.profile_id}.first    
    
  end

  def as_json(options = {})
    tabledata = data
    {
      recordsTotal: tabledata[1],
      recordsFiltered: tabledata[1],
      data: tabledata[0]
    }
  end

private

  def data

    collections = get_collections()
    collection_hash = get_collection_names(collections)
 
    data = display_on_page(collections)
    formatted_data = data.map do |entry|
      [
       link_to(entry[:title], analytic_path(entry[:dimension1])),
       entry[:users],
       entry[:totalEvents]
      ]
    end
    return formatted_data, data.total_count
  end

  # Get collections for which we have manage permissions
  # TODO consider admin
  # if none then just return empty array
  # else get analytics for these collection ids and return analytics
  def fetch_analytics(collections)
    return collections if collections.empty?

    views = AnalyticsCollectionUsers.results(@profile, :start_date => startdate, :end_date => enddate).collections(*collections).to_a
    downloads = AnalyticsCollectionEvents.results(@profile, :start_date => startdate, :end_date => enddate).collections(*collections).action('Download').to_a

    downloads.map{|r| r[:dimension1] = r.delete_field(:eventCategory) }
    analytics = (views+downloads).map{|a| a.to_h }.group_by{|h| h[:dimension1] }.map{|k,v| v.reduce({}, :merge)}

    collection_hash = get_collection_names(collections)
    analytics.map{ |r| r[:title] = collection_hash[r[:dimension1]] }

    if sort_column.eql?('title')
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym] }
    else
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym].to_i }
    end
    analytics.reverse! if sort_direction.eql?('desc')

    return analytics
  end

  def display_on_page(collections)
    return Kaminari.paginate_array(fetch_analytics(collections)).page(page).per(per_page)
  end 

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[title users totalEvents]
    return columns[params[:order][:'0'][:column].to_i]
  end

  def sort_direction
    params[:order][:'0'][:dir] == "desc" ? "desc" : "asc"
  end

  def startdate
    params[:startdate] || Date.today.at_beginning_of_month()
  end

  def enddate
    params[:enddate] || Date.today
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

  def get_collection_names(collections)
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(collections)
    object_docs = ActiveFedora::SolrService.query(query,
                  :'fl' => "id, #{ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)}" )
    collection_hash = {}
    object_docs.map { |o| collection_hash[o["id"]] = o["#{ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)}"].first }
    return collection_hash
  end
    
end
