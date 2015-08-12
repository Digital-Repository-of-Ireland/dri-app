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
    if (description.length > count)
      return description.first(count)
    else
      return description
    end
  end

  # Workaround for reusing partials for add institution/permissions to non QDC collections
  #
  def update_desc_metadata? md_class
    (["DRI::QualifiedDublinCore", "DRI::Documentation"].include? md_class) ? true : false
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
    begin
      object = DRI::Batch.find(document["id"])

      if (!object.nil? && object.class != DRI::Documentation)
        unless (object.class == DRI::EncodedArchivalDescription)
          object.get_relationships_records.each do |rel, value|
            display_label = object.get_relationships_names[rel]
            item_array = []
            value.each do |id|
              rel_obj_doc = ActiveFedora::SolrService.query("id:#{id}", :defType => "edismax")
              unless rel_obj_doc.empty?
                link_text = rel_obj_doc[0][Solrizer.solr_name('title', :stored_searchable, type: :string)].first
                item_array.to_a.push [link_text, catalog_path(rel_obj_doc[0]["id"]).to_s]
              end
            end
            relationships_hash["#{display_label}"] = Kaminari.paginate_array(item_array).page(params[display_label.downcase.gsub(/\s/,'_') << "_page"]).per(4) unless item_array.empty?
          end # each
        end
        unless object.documentation_object_ids.nil? || object.documentation_object_ids.empty?
          doc_array = []
          object.documentation_object_ids.each do |id|
            doc_obj = ActiveFedora::SolrService.query("id:#{id}", :defType => "edismax")
            unless doc_obj.empty?
              link_text = doc_obj[0][Solrizer.solr_name('title', :stored_searchable, type: :string)].first
              doc_array.to_a.push [link_text, catalog_path(doc_obj[0]["id"]).to_s]
            end
          end
          relationships_hash["Has Documentation"] = Kaminari.paginate_array(doc_array).page(params["Has Documentation".downcase.gsub(/\s/,'_') << "_page"]).per(4) unless doc_array.empty?
        end
      elsif object.class == DRI::Documentation
        unless object.documentation_for_id.nil?
          link_text = object.documentation_for.title.first
          relationships_hash["Is Documentation For"] = Kaminari.paginate_array([[link_text, catalog_path(object.documentation_for_id).to_s]]).page(params["Is Documentation For".downcase.gsub(/\s/,'_') << "_page"]).per(4)
        end
      end
    rescue ActiveFedora::ObjectNotFoundError
      Rails.logger.error("Object not found: #{document["id"]}")
    end
=begin
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
=end

    return relationships_hash
  end # get_object_relationships

  # Returns an Array with all the URLS of related materials for UI Display
  # @param[Solr::Document] document the Solr document of the object to display relations for
  # @return Array external related materials
  #
  def get_object_external_relationships document
    url_array = []

    if document.active_fedora_model
      case document.active_fedora_model
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
