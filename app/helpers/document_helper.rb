module DocumentHelper
  Child = Struct.new(:id, :link_text, :path, :type, :cover) do
    def to_partial_path
      'child'
    end
  end

  def get_collection_media_type_params(document, collection_id, media_type)
    search_facets = if document[Solrizer.solr_name('collection_id', :stored_searchable, type: :string)].nil?
      {
        Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [media_type],
        Solrizer.solr_name('root_collection_id', :facetable, type: :string).to_sym => [collection_id]
      }
    else
      {
        Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [media_type],
        Solrizer.solr_name('ancestor_id', :facetable, type: :string).to_sym => [collection_id]
      }
    end
    search_params = { mode: 'objects', search_field: 'all_fields', utf8: '✓', f: search_facets }

    search_params
  end

  def truncate_description(description, count)
    description.length > count ? description.first(count) : description
  end

  # Workaround for reusing partials for add
  # institution/permissions to non QDC collections
  def update_desc_metadata?(md_class)
    %w(DRI::QualifiedDublinCore DRI::Documentation DRI::Mods DRI::Marc).include?(md_class) ? true : false
  end

  # For a given collection (sub-collection) object
  # returns a list of the immediate child sub-collections
  def collection_children(document, limit)
    children_array = []
    children = document.children(limit)
    count = 0;
    children.each do |doc|
      next unless doc.published? || ((current_user && current_user.is_admin?) || can?(:edit, doc))

      link_text = doc[Solrizer.solr_name('title', :stored_searchable, type: :string)].first
      # FIXME: For now, the EAD type is indexed last in the type solr index, review in the future
      type = doc[Solrizer.solr_name('type', :stored_searchable, type: :string)].last
      cover = doc[Solrizer.solr_name('cover_image', :stored_searchable, type: :string).to_sym].presence

      child = Child.new
      child.id = doc['id']
      child.link_text = link_text
      child.path = catalog_path(doc['id'])
      child.cover = cover
      child.type = type

      children_array = children_array.to_a.push(child)
    end

    children_array
  end
end
