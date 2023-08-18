class AnalyticsCollectionDatatable
  delegate :current_user, :params, :solr_document_path, :link_to, to: :@view
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
    data = display_on_page(collection_id)
    formatted_data = data.map do |entry|
      [
       link_to(entry[:title], solr_document_path(entry[:object])),
       entry[:users],
       entry[:totalHits],
       entry[:totalEvents]
      ]
    end
    return formatted_data, data.total_count
  end

  # Get collections for which we have manage permissions
  # TODO consider admin
  # if none then just return empty array
  # else get analytics for these collection ids and return analytics
  def fetch_analytics(collection)
    ga4 = ga4_analytics(collection)
    ua = ua_analytics(collection)
   
    analytics = (ga4+ua).map{|a| a.to_h }.group_by{|h| h[:object] }.map{|k,v| v.reduce({}, :merge)}
    
    analytics.each do |entry|
      entry[:users] = entry[:users].to_i + entry[:ga4_users].to_i if entry[:ga4_users].present?
      entry[:totalEvents] = entry[:totalEvents].to_i + entry[:ga4_totalEvents].to_i if entry[:ga4_totalEvents].present?
      entry[:totalHits] = entry[:totalHits].to_i + entry[:ga4_totalHits].to_i if entry[:ga4_totalHits].present? 
    end

    object_hash = object_titles(collection)
    analytics.each{ |r| r[:title] = object_hash[r[:object]] }

    if sort_column == 'title'
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym] }
    else
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym].to_i }
    end
    analytics.reverse! if sort_direction == 'desc'

    analytics
  end

  def ua_analytics(collection)
    views = AnalyticsObjectUsers.results(@profile, start_date: startdate, end_date: enddate).collection(collection).to_a
    downloads = AnalyticsObjectEvents.results(@profile, start_date: startdate, end_date: enddate).collection(collection).action('Download').to_a
    
    views.each do |r| 
      r[:object] = URI(r.delete_field(:pagepath)).path.split('/').last
      r[:totalHits] = r.delete_field(:pageviews)
    end
    downloads.each {|r| r[:object] = r.delete_field(:eventLabel) }

    (views+downloads)
  end

  def ga4_analytics(collection)
    views = DRI::Analytics.object_events_users(startdate, enddate, [collection])
    downloads = DRI::Analytics.object_events_downloads(startdate, enddate, [collection])
    hits = DRI::Analytics.object_events_hits(startdate, enddate, [collection])

    views.each do |r| 
      r[:object] = r.delete('customEvent:object')
      r[:ga4_users] = r.delete('totalUsers')
    end

    downloads.each do |r| 
      r[:object] = r.delete('customEvent:object')
      r[:ga4_totalEvents] = r.delete('eventCount')
    end
    hits.each do |r| 
      r[:object] = r.delete('customEvent:object')
      r[:ga4_totalHits] = r.delete('eventCount')
    end

    (views+hits+downloads)
  end

  def display_on_page(collection)
    Kaminari.paginate_array(fetch_analytics(collection)).page(page).per(per_page)
  end

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 10
  end

  def sort_column
    columns = %w[title users totalHits totalEvents]
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

  def collection_id
    params[:id]
  end

  def item_id(entry)
    if entry.item_type == 'UserGroup::User'
        user = UserGroup::User.find(entry.item_id)
        user.nil? ? entry.item_id : link_to(UserGroup::User.find(entry.item_id).to_s, user_path(entry.item_id))
    elsif entry.item_type == 'UserGroup::Membership'
      entry.item_id
    end
  end

  def object_titles(collection_id)
    query = "(id:\"" + collection_id + "\" OR ancestor_id_ssim:\"" + collection_id + "\")"
    solr_query = Solr::Query.new(query)
    object_hash = {}
    solr_query.each do |o|
      object_hash[o["id"]] = o["title_tesim"].first
    end
    object_hash
  end
end
