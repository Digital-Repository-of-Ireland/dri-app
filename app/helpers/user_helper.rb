module UserHelper


  # Return all collection permissions
  def get_collection_permission
    manage = get_manage_collections(@current_user.email)
    manage.map{ |item| item[:permission] = "Collection Manager" }
    edit = get_edit_collections(@current_user.email)
    edit.map{ |item| item[:permission] = "Editor" }
    read = get_read_collections(@current_user.email)
    read.map{ |item| item[:permission] = "Reader" }
    return manage.concat(edit).concat(read)
  end


  # Return array of collections managed by a given user
  def get_manage_collections(user)
    query = Solr::Query.new("#{Solrizer.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{user}")

    collections = []
    while query.has_more?
      objects = query.pop
      objects.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[Solrizer.solr_name('title', :stored_searchable, type: :string)]
        collections.push(collection)
      end
    end
    return collections
  end


  # Return array of collections editable by a given user
  def get_edit_collections(user)
    query = Solr::Query.new("#{Solrizer.solr_name('edit_access_person', :stored_searchable, type: :symbol)}:#{user}")

    collections = []
    while query.has_more?
      objects = query.pop
      objects.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[Solrizer.solr_name('title', :stored_searchable, type: :string)]
        collections.push(collection)
      end
    end
    return collections
  end


  def get_read_collections(user)

    group_query_fragments = UserGroup::User.where(:email => user).first.groups.map{ |group| "#{Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)}:#{group.name}" }
    return [] if group_query_fragments.blank?
    group_query_string = group_query_fragments.join(" OR ")
    query = Solr::Query.new("#{Solrizer.solr_name('read_access_group', :stored_searchable, type: :symbol)}:dri* AND (#{group_query_string})")

    collections = []
    while query.has_more?
      objects = query.pop
      objects.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[Solrizer.solr_name('title', :stored_searchable, type: :string)]
        collections.push(collection)
      end
    end
    return collections
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
