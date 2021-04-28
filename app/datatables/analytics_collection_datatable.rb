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
       link_to(entry[:title], solr_document_path(entry[:dimension3])),
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
    views = AnalyticsObjectUsers.results(@profile, start_date: startdate, end_date: enddate).collection(collection).to_a
    downloads = AnalyticsObjectEvents.results(@profile, start_date: startdate, end_date: enddate).collection(collection).action('Download').to_a
    hits = AnalyticsObjectEvents.results(@profile, start_date: startdate, end_date: enddate).collection(collection).action('View').to_a

    downloads.map{|r| r[:dimension3] = r.delete_field(:eventLabel) }
    hits.map{|r| r[:dimension3] = r.delete_field(:eventLabel) }
    hits.map{|r| r[:totalHits] = r.delete_field(:totalEvents) }

    analytics = (views+hits+downloads).map{|a| a.to_h }.group_by{|h| h[:dimension3] }.map{|k,v| v.reduce({}, :merge)}

    object_hash = get_object_names(collection)
    analytics.map{ |r| r[:title] = object_hash[r[:dimension3]] }

    if sort_column == 'title'
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym] }
    else
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym].to_i }
    end
    analytics.reverse! if sort_direction == 'desc'

    analytics
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
    params[:startdate] || Date.today.at_beginning_of_month()
  end

  def enddate
    params[:enddate] || Date.today
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

  def get_object_names(collection_id)
    query = "(id:\"" + collection_id + "\" OR ancestor_id_ssim:\"" + collection_id +
    "\" OR #{Solrizer.solr_name('is_member_of_collection', :stored_searchable, type: :symbol)}:\"info:fedora/" + collection_id + "\" )"
    solr_query = Solr::Query.new(query)
    object_hash = {}
    while solr_query.has_more?
      objects = solr_query.pop
      objects.map { |o| object_hash[o["id"]] = o["#{Solrizer.solr_name('title', :stored_searchable, type: :string)}"].first }
    end
    object_hash
  end
end
