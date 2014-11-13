module TimelineHelper

  def get_query params
    query = ""

    if params[:mode] == 'collections'
      query += "#{Solrizer.solr_name('file_type', :stored_searchable, type: :string)}:collection"
    else
      query += "-#{Solrizer.solr_name('file_type', :stored_searchable, type: :string)}:collection"
    end

    unless signed_in?
      query += " AND #{Solrizer.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

    unless params[:q].blank?
      query += " AND #{params[:q]}"
    end

    unless params[:f].blank?
      params[:f].each do |facet_name, facet_value|
        query += " AND #{facet_name}:\"#{facet_value.first}\""
      end
    end

    # creation date exists and it is valid
    query += " AND #{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:[* TO *]"
    query += " AND (-#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:unknown"
    query += " AND -#{Solrizer.solr_name('creation_date', :stored_searchable, type: :string)}:\"n/a\")"

    return query
  end

  def get_valid_timeline_count params
    query = get_query params
    count = ActiveFedora::SolrService.count(query, :defType => "edismax")
    return count
  end

end