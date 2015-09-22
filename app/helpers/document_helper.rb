module DocumentHelper

  def get_collection_media_type_params document, collectionId, mediaType
    if document[Solrizer.solr_name('collection_id', :stored_searchable, type: :string)] == nil
      searchFacets = { Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [mediaType], Solrizer.solr_name('root_collection_id', :facetable, type: :string).to_sym => [collectionId] }
    else
      searchFacets = { Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [mediaType], Solrizer.solr_name('ancestor_id', :facetable, type: :string).to_sym => [collectionId] }
    end
    searchParams = { :mode => "objects", :search_field => "all_fields", :utf8 => "✓", :f => searchFacets }
    
    searchParams
  end

  def truncate_description description, count
    (description.length > count) ? description.first(count) : description
  end

  # Workaround for reusing partials for add institution/permissions to non QDC collections
  #
  def update_desc_metadata? md_class
    (["DRI::QualifiedDublinCore", "DRI::Documentation", "DRI::Marc"].include? md_class) ? true : false
  end

  # For a given collection (sub-collection) object returns a list of the immediate child sub-collections
  def get_collection_children document, limit
    children_array = []
    # Find all immediate children of this collection
    solr_query = "#{Solrizer.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{document['id']}\""
    f_query = if current_user && current_user.is_admin?
           "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true "
         else
           "(#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true " +
           "AND #{Solrizer.solr_name('status', :stored_searchable, type: :string)}:published)"
         end

    # Filter to only get those that are collections: fq=is_collection_tesim:true
    q_result = Solr::Query.new(solr_query, limit, :fq => f_query)

    while (q_result.has_more?)
      objects_docs = q_result.pop
      objects_docs.each do |obj_doc|
        doc = SolrDocument.new(obj_doc)
        link_text = doc[Solrizer.solr_name('title', :stored_searchable, type: :string)].first
        # FIXME For now, the EAD type is indexed last in the type solr index, review in the future
        type = doc[Solrizer.solr_name('type', :stored_searchable, type: :string)].last

        children_array = children_array.to_a.push [link_text, catalog_path(doc['id']).to_s, type.to_s]
      end
    end
    paged_children = Kaminari.paginate_array(children_array).page(params[:subs_page]).per(4)
    return paged_children
  end

  def get_object_relationships document
    relationships = document.object_relationships
    filtered_relationships = {}

    relationships.each do |key, array|
      filtered_array = array.select{|item| item[1].published? || ((current_user && current_user.is_admin?) || can?(:edit, item[1]))}
      filtered_relationships[key] = Kaminari.paginate_array(filtered_array).page(params[key.downcase.gsub(/\s/,'_') << "_page"]).per(4) unless filtered_array.empty?
    end

    filtered_relationships
  end

  def get_external_relationships document
    Kaminari.paginate_array(document.external_relationships).page(params[:externs_page]).per(4)
  end

end
