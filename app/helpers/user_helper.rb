module UserHelper
  def admin_collections_data(admin)
    query = Solr::Query.new(
      "#{ActiveFedora.index_field_mapper.solr_name('depositor', :searchable, type: :symbol)}:#{admin.email}",
      100,
      { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"] }
    )

    collections = collections(admin, query)
    collections.map { |item| item[:permission] = 'Depositor' }
    Kaminari.paginate_array(collections).page(params[:page]).per(9)
  end

  def collections(user, query)
    collections = []

    while query.has_more?
      objects = query.pop
      objects.each do |object|
        collection = {}
        collection[:id] = object['id']
        collection[:collection_title] = object[
          ActiveFedora.index_field_mapper.solr_name(
          'title', :stored_searchable, type: :string
          )
        ]

        permissions = []
        type = user_type(user, object, 'manager', 'Collection Manager')
        permissions << type if type

        type = user_type(user, object, 'edit', 'Editor')
        permissions << type if type

        collection[:permission] = permissions.join(', ') if permissions
        collections.push(collection)
      end
    end

    collections
  end

  # Return all collection permissions
  # if no user passed in use @current_user
  def collection_permission(user = nil)
    profile_user = user ? user : @current_user

    if profile_user.is_admin?
      admin_collections_data(profile_user)
    else
      user_collections_data(profile_user)
    end
  end

  def user_collections_data(user)
    query = "#{ActiveFedora.index_field_mapper.solr_name('manager_access_person', :stored_searchable, type: :symbol)}:#{user.email} OR "\
      "#{ActiveFedora.index_field_mapper.solr_name('edit_access_person', :stored_searchable, type: :symbol)}:#{user.email}"

    read_query = read_group_query(user)
    query <<   " OR (" + read_query + ")" unless read_query.nil?

    solr_query = Solr::Query.new(
      query,
      100,
      { fq: ["+#{ActiveFedora.index_field_mapper.solr_name('is_collection', :facetable, type: :string)}:true",
            "-#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:[* TO *]"]}
    )

    Kaminari.paginate_array(collections(user, solr_query)).page(params[:page]).per(9)
  end

  def read_group_query(user)
    group_query_fragments = user.groups.map do |group|
      "#{ActiveFedora.index_field_mapper.solr_name(
        'read_access_group', :stored_searchable, type: :symbol)}:#{group.name}" unless group.name == "registered"
    end
    return nil if group_query_fragments.compact.blank?
    group_query_fragments.compact.join(" OR ")
  end

  def user_type(user, object, role, label)
    user_type = nil
    
    key = ActiveFedora.index_field_mapper.solr_name("#{role}_access_person", :stored_searchable, type: :symbol)
    if object[key].present?
      user_type = label if object[key].include?(user.email)
    end

    user_type
  end

  def get_saved_search_snippet_documents(search_params)
    solr_query = get_saved_search_solr_query(search_params)
    ActiveFedora::SolrService.query(solr_query, defType: "edismax", rows: "3")
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
