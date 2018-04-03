module DocumentHelper
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
end
