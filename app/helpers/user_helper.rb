module UserHelper
  #TO BE DELETED once the functionality has been developed
  def get_collection_permission
    if current_user.is_admin? || current_user.is_cm?
      fake_data = [{:collection_title => "Fake Collection 1", :permission => "Collection Manager"}, {:collection_title => "Fake Collection 2", :permission => "Editor"}]
      return fake_data
    else
      return ""
    end
  end

  def get_saved_search_snippet_documents(search_params)
    solr_query = get_saved_search_solr_query(search_params)
    ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => "3")
  end

  def get_saved_search_count(search_params)
    solr_query = get_saved_search_solr_query(search_params)
    ActiveFedora::SolrService.count(solr_query, :defType => "edismax")
  end

  def get_saved_search_solr_query(search_params)
    solr_query = get_saved_search_mode(search_params[:mode])
    query_permissions = get_saved_search_permission_filter
    unless query_permissions.blank?
      solr_query = solr_query + " AND " + query_permissions
    end
    query_params = get_saved_search_query(search_params[:q])
    unless query_params.blank?
      solr_query = solr_query + " AND " + query_params
    end
    query_facets = get_saved_search_facets(search_params[:f])
    unless query_facets.blank?
      solr_query = solr_query + " AND " + query_facets
    end
    return solr_query
  end

  def get_saved_search_permission_filter
    if current_user.is_admin? || current_user.is_cm?
      return ""
    else
      return "status_ssim:published"
    end
  end

  def get_saved_search_query(search_q)
    if (search_q.blank?)
      return ""
    else
      return "#{search_q} "
    end
  end

  def get_saved_search_mode(search_mode)
    mode = "file_type_tesim:collection"
    unless search_mode == "collections"
      mode = "-#{mode}"
    end
    return "#{mode} "
  end

  def get_saved_search_facets(search_f)
    if search_f.blank?
      return ""
    else
      facets = ""
      i = 0
      search_f.each do |key, value|
        i+=1
        facets = facets + key.to_s + ":\"" + value.first.to_s + "\""
        unless i == search_f.count
          facets = facets + " AND "
        end
      end
    return facets
    end
  end

end