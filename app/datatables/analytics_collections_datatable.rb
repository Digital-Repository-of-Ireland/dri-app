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

    views = AnalyticsCollectionUsers.results(@profile, start_date: startdate, end_date: enddate).collections(*collections).to_a
    downloads = AnalyticsCollectionEvents.results(@profile, start_date: startdate, end_date: enddate).collections(*collections).action('Download').to_a

    downloads.map{|r| r[:dimension1] = r.delete_field(:eventCategory) }
    analytics = (views+downloads).map{|a| a.to_h }.group_by{|h| h[:dimension1] }.map{|k,v| v.reduce({}, :merge)}

    collection_hash = get_collection_names(collections)
    analytics.map{ |r| r[:title] = collection_hash[r[:dimension1]] }

    if sort_column == 'title'
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym] }
    else
      analytics.sort_by! { |hsh| hsh[sort_column.to_sym].to_i }
    end
    analytics.reverse! if sort_direction == 'desc'

    analytics
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
    params[:startdate] || Date.today.at_beginning_of_month()
  end

  def enddate
    params[:enddate] || Date.today
  end

  def get_collections
    collections = []

    query = if current_user.is_admin?
              "*:*"
            else
              "#{ActiveFedora.index_field_mapper.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{current_user.email}"
            end
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

    collections
  end

  def get_collection_names(collections)
    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(collections)
    solr_query = Solr::Query.new(query)
    collection_hash = {}
    while solr_query.has_more?
      object_docs = solr_query.pop
      object_docs.map do |o| 
        collection_hash[o["id"]] = o["#{ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)}"].first
      end
    end
    collection_hash
  end
    
end
