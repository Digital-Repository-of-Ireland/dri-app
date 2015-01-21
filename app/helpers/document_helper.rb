module DocumentHelper

  def get_document_type document

    case document[Solrizer.solr_name('file_type_display', :stored_searchable, type: :string).to_sym].first.to_s.downcase
      when "image"
        return t("dri.data.types.Image")
      when "audio"
        return t("dri.data.types.Sound")
      when "video"
        return t("dri.data.types.MovingImage")
      when "text"
        return t("dri.data.types.Text")
      when "mixed_types"
        return t("dri.data.types.MixedType")
      else
        return t("dri.data.types.Unknown")
    end

  end

  def get_collection_media_type_params document, collectionId, mediaType
    if document[Solrizer.solr_name('collection_id', :stored_searchable, type: :string)] == nil
      searchFacets = { Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [mediaType], Solrizer.solr_name('root_collection_id', :facetable, type: :string).to_sym => [collectionId] }
    else
      searchFacets = { Solrizer.solr_name('file_type_display', :facetable, type: :string).to_sym => [mediaType], Solrizer.solr_name('ancestor_id', :facetable, type: :string).to_sym => [collectionId] }
    end
    searchParams = { :mode => "objects", :search_field => "all_fields", :utf8 => "✓", :f => searchFacets }
    return searchParams
  end

  def truncate_description description, count
    if (description.length > count)
      return description.first(count)
    else
      return description
    end
  end

  # Check, based on the document type (Fedora active_fedora_model), whether edit functions are available
  def edit_functionality_available? document
    (document['active_fedora_model_ssi'] && document['active_fedora_model_ssi'] == 'DRI::EncodedArchivalDescription') ? false : true
  end

  # For a given EAD collection object returns a list of the immediate child sub-collections
  def show_ead_tree document, limit
    html_display = ""
    solr_query = "#{Solrizer.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{document['id']}\""
    # FIXME I've put a fixed number of results back to avoid the solr default of 10 but need to investigate how to return ALL
    docs = ActiveFedora::SolrService.query(solr_query, :defType => "edismax", :rows => limit)
    if (docs != [])
      html_display = "<ul>"
      docs.each do |curr_doc|
        # array_ancestors = curr_doc[Solrizer.solr_name('ancestor_id', :stored_searchable, type: :string)]
        # if (array_ancestors.last == document['id'])
          html_display = html_display + "<li>"

          link_text = curr_doc[Solrizer.solr_name('title', :stored_searchable, type: :string)].first + " (" +
            curr_doc[Solrizer.solr_name('type', :stored_searchable, type: :string)].first + ")"

          html_display = html_display + link_to( link_text, catalog_path(curr_doc['id']), :id => 'view_collection' ) + "</li>"
        #end
      end
      html_display = html_display + "</ul>"
    end

    return html_display
  end

end
