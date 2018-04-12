module UserHelper

  # Return all collection permissions
  # if no user passed in use @current_user
  def collection_permission(user = nil)
    profile_user = user ? user : @current_user
    user_collections = UserCollections.new(user: profile_user)

    Kaminari.paginate_array(user_collections.collections_data).page(params[:page]).per(5)
  end
  
  def get_saved_search_snippet_documents(search_params)
    solr_query = get_saved_search_solr_query(search_params)
    results = ActiveFedora::SolrService.query(solr_query, defType: "edismax", rows: "3")
    results.map { |doc| SolrDocument.new(doc) }
  end

  def get_saved_search_count(search_params)
    solr_query = get_saved_search_solr_query(search_params)
    ActiveFedora::SolrService.count(solr_query, defType: "edismax")
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

    solr_query
  end

  def get_saved_search_permission_filter
    if current_user.is_admin? || current_user.is_cm?
      ""
    else
      "#{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end
  end

  def get_saved_search_query(search_q)
    if search_q.blank?
      ""
    else
      "#{search_q} "
    end
  end

  def get_saved_search_mode(search_mode)
    mode = "#{ActiveFedora.index_field_mapper.solr_name('file_type', :stored_searchable, type: :string)}:collection"
    unless search_mode == "collections"
      mode = "-#{mode}"
    end

    "#{mode} "
  end

  def get_saved_search_facets(search_f)
    return "" if search_f.blank?

    facets = ""
    i = 0
    search_f.each do |key, value|
      i += 1
      facets += key.to_s + ":\"" + value.first.to_s + "\""
      facets += " AND " unless i == search_f.count
    end

    facets
  end

  def get_inherited_read_groups(obj)
    return if obj == nil
    if obj.read_groups.empty?
      get_inherited_read_groups(obj.governing_collection)
    elsif obj.read_groups.first == 'registered'
      return "logged-in"
    elsif obj.read_groups.first == 'public'
      return "public"
    else 
      return "restricted"
    end
  end

  def get_inherited_masterfile_access(obj)
    return if obj == nil
    return obj.master_file_access unless obj.master_file_access == "inherit" || obj.master_file_access == nil
    get_inherited_masterfile_access(obj.governing_collection)
  end

end
