module DocumentHelper
  def collection_media_type_params(document, collection_id, media_type)
    search_facets = { file_type_display_sim: [media_type] }

    if document.root_collection?
      search_facets[:root_collection_id_ssi] = [collection_id]
    else
      search_facets[:ancestor_id_ssim] = [collection_id]
    end

    { mode: 'objects', search_field: 'all_fields', utf8: '✓', f: search_facets }
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
