class AnalyticsCollectionsDatatable
  delegate :current_user, :params, :analytic_path, :link_to, to: :@view
  delegate :user_path, to: 'UserGroup::Engine.routes.url_helpers'

  def initialize(profile, view)
    @view = view
    @profile = profile
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
    collections = get_collections
    collection_hash = collection_names(collections)

    data = display_on_page(collections)
    formatted_data = data.map do |entry|
      [
       link_to(entry[:title], analytic_path(entry[:collection])),
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

    analytics = if Settings.analytics.provider == 'ga4'
                  ga4_analytics(collections)
                else
                  ua_analytics(collections)
                end

    analytics = analytics.map{|a| a.to_h }.group_by{|h| h[:collection] }.map{|k,v| v.reduce({}, :merge)}

    collection_hash = collection_names(collections)
    analytics.each{ |r| r[:title] = collection_hash[r[:collection]] }

    if sort_column == 'title'
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym] }
    else
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym].to_i }
    end
    analytics.reverse! if sort_direction == 'desc'

    analytics
  end

  def ua_analytics(collections)
    views = AnalyticsCollectionUsers.results(@profile, start_date: startdate, end_date: enddate).collections(*collections).to_a
    downloads = AnalyticsCollectionEvents.results(@profile, start_date: startdate, end_date: enddate).collections(*collections).action('Download').to_a

    views.each{|r| r[:collection] = r.delete_field(:dimension1) }
    downloads.each{|r| r[:collection] = r.delete_field(:eventCategory) }
    
    (views+downloads)
  end

  def ga4_analytics(collections)
    views = DRI::Analytics.object_events_users(startdate, enddate, collections)
    downloads = DRI::Analytics.object_events_downloads(startdate, enddate, collections)
    
    views.each do |r| 
      r[:collection] = r.delete('customEvent:collection')
      r[:users] = r.delete('totalUsers')
    end

    downloads.each do |r| 
      r[:collection] = r.delete('customEvent:collection')
      r[:totalEvents] = r.delete('eventCount')
    end
 
    (views+downloads)
  end

  def display_on_page(collections)
    Kaminari.paginate_array(fetch_analytics(collections)).page(page).per(per_page)
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
    params[:startdate] || Date.today.at_beginning_of_month().strftime('%Y-%m-%d')
  end

  def enddate
    params[:enddate] || Date.today.strftime('%Y-%m-%d')
  end

  def get_collections
    collections = []

    query = if current_user.is_admin?
              params[:user].present? ? "manager_access_person_ssim:#{params[:user]}" : "*:*"
            else
              "#{Solrizer.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{current_user.email}"
            end
    solr_query = Solr::Query.new(
      query,
      100,
      { fq: ["is_collection_ssi:true",
            "-ancestor_id_ssim:[* TO *]"]}
    )

    while solr_query.has_more?
      objects = solr_query.pop
      objects.each do |object|
        collections.push(object['id'])
      end
    end

    collections
  end

  def collection_names(collections)
    query = Solr::Query.construct_query_for_ids(collections)
    solr_query = Solr::Query.new(query)
    collection_hash = {}
    solr_query.each do |o|
      collection_hash[o["id"]] = o["title_tesim"].first
    end
    collection_hash
  end
end
