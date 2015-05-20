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
    (!document['active_fedora_model_ssi'].nil? && document['active_fedora_model_ssi'] == 'DRI::EncodedArchivalDescription') ? false : true
  end

  # Workaround for reusing partials for add institution/permissions to non QDC collections
  #
  def update_desc_metadata? md_class
    (["DRI::QualifiedDublinCore", "DRI::Documentation"].include? md_class) ? true : false
  end

  def get_active_fedora_model document
    document['active_fedora_model_ssi'] unless document['active_fedora_model_ssi'].nil?
  end

  # For a given collection (sub-collection) object returns a list of the immediate child sub-collections
  def get_collection_children document, limit
    children_array = []
    # Find all immediate children of this collection
    solr_query = "#{Solrizer.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{document['id']}\""
    # Filter to only get those that are collections: fq=is_collection_tesim:true
    q_result = Solr::Query.new(solr_query, limit, :fq => "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true")

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

  # Returns a Hash with relationship groups and generated links to related objects for UI Display
  # @param[Solr::Document] document the Solr document of the object to display relations for
  # @return Hash related items grouped by type of relationship
  #
  def get_object_relationships document
    relationships_hash = Hash.new
    object = nil

    if document['active_fedora_model_ssi']
      case document['active_fedora_model_ssi']
        when 'DRI::Mods'
          object = DRI::Mods.find(document["id"])
        when 'DRI::QualifiedDublinCore'
          object = DRI::QualifiedDublinCore.find(document["id"])
        when 'DRI::Marc'
          object = DRI::Marc.find(document["id"])
        else # case EAD, does not have internal DRI relationships
          object = nil
      end # end case
    end
        
    unless (object.nil?)
      object.get_relationships_names.each do |rel, display_label|
        unless (object.send("#{rel}").nil?)
          if (object.send("#{rel}").respond_to?("push"))
            item_array = []
            # e.g. constituents rel: object.constituents (holds all the constituents object - inefficient)
            # object.constituent_ids (returns an array of all the foreign-key IDS for the constituents)
            # Use these instead: "constituents".singularize << "_ids"
            object.send("#{rel}".singularize << "_ids").each do |id|
              rel_obj_doc = ActiveFedora::SolrService.query("id:#{id}", :defType => "edismax")
              unless rel_obj_doc.empty?
                link_text = rel_obj_doc[0][Solrizer.solr_name('title', :stored_searchable, type: :string)].first
                item_array.to_a.push [link_text, catalog_path(rel_obj_doc[0]["id"]).to_s]
              end
            end
            relationships_hash["#{display_label}"] = Kaminari.paginate_array(item_array).page(params[display_label.downcase.gsub(/\s/,'_') << "_page"]).per(4) unless item_array.empty?
          else
            link_text = object.send("#{rel}").title.first
            relationships_hash["#{display_label}"] = Kaminari.paginate_array([[link_text, catalog_path(object.send("#{rel}").pid).to_s]]).page(params[display_label.downcase.gsub(/\s/,'_') << "_page"]).per(4)
          end
        end
      end # each
    end 
    return relationships_hash
  end # get_object_relationships

  # Returns an Array with all the URLS of related materials for UI Display
  # @param[Solr::Document] document the Solr document of the object to display relations for
  # @return Array external related materials
  #
  def get_object_external_relationships document
    url_array = []

    if document['active_fedora_model_ssi']
      case document['active_fedora_model_ssi']
        when 'DRI::Mods'
          solr_fields_array = *(DRI::Vocabulary::modsRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym})
        when 'DRI::QualifiedDublinCore'
          solr_fields_array = *(DRI::Vocabulary::qdcRelationshipTypes.map { |s| s.prepend("ext_related_items_ids_").to_sym})
        when 'DRI::Marc', 'DRI::EncodedArchivalDescription'
          solr_fields_array = [:related_material, :alternative_form]
        else
          solr_fields_array = nil
      end
    end

    unless solr_fields_array.nil?
      solr_fields_array.each do |elem|
        if (!document[Solrizer.solr_name(elem, :stored_searchable, type: :string)].nil? && !document[Solrizer.solr_name(elem, :stored_searchable, type: :string)].empty?)
          url_array = url_array.to_a.push(*document[Solrizer.solr_name(elem, :stored_searchable, type: :string)])
        end
      end
    end
    
    return Kaminari.paginate_array(url_array).page(params[:externs_page]).per(4)
  end # get_object_external_relationships

end
