module DRI::Solr::Document::Relations

  # Returns an Array with all the URLS of related materials for UI Display
  # @param[Solr::Document] document the Solr document of the object to display relations for
  # @return Array external related materials
  #
  def external_relationships params
    url_array = []

    if active_fedora_model
      case active_fedora_model
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

    if solr_fields_array
      solr_fields_array.each do |elem|
        key = ActiveFedora::SolrQueryBuilder.solr_name(elem, :stored_searchable, type: :string)

        url_array = url_array.to_a.push(*self[key]) if self[key].present?
      end
    end
    
    Kaminari.paginate_array(url_array).page(params[:externs_page]).per(4)
  end

  # Returns a Hash with relationship groups and generated links to related objects for UI Display
  # @param[Solr::Document] document the Solr document of the object to display relations for
  # @return Hash related items grouped by type of relationship
  #
  def object_relationships params
    relationships_hash = Hash.new
    
    begin
      
      if active_fedora_model == "DRI::Documentation"
        documentation = documentation_for

        if documentation
          link_text = documentation[ActiveFedora::SolrQueryBuilder.solr_name('title')].first
          relationships_hash["Is Documentation For"] = Kaminari.paginate_array([[link_text, documentation.id]]).page(params["Is Documentation For".downcase.gsub(/\s/,'_') << "_page"]).per(4)
        end
      else
        relationships_hash.merge!(get_relationships params) unless active_fedora_model == "DRI::EncodedArchivalDescription"
        relationships_hash.merge!(get_documentation params["Has Documentation".downcase.gsub(/\s/,'_') << "_page"])
      end

    rescue ActiveFedora::ObjectNotFoundError
      Rails.logger.error("Object not found: #{document["id"]}")
    end

    return relationships_hash
  end # get_object_relationships

  private

  def get_documentation has_documentation_page
    docs = {}
    doc_array = []
    
    documentation_ids = documentation_object_ids
    documentation_ids.each do |id|
      doc_obj = ActiveFedora::SolrService.query("id:#{id}", :defType => "edismax")

      unless doc_obj.empty?
        link_text = doc_obj[0][ActiveFedora::SolrQueryBuilder.solr_name('title', :stored_searchable, type: :string)].first
        doc_array.to_a.push [link_text, doc_obj[0]["id"]]
      end

    end
    docs["Has Documentation"] = Kaminari.paginate_array(doc_array).page(has_documentation_page).per(4) unless doc_array.empty?

    docs
  end

  def get_relationships params
    rels = {}

    relationships_records.each do |rel, value|
      display_label = active_fedora_model.constantize.relationships[rel][:label]
      item_array = []
      value.each do |id|
        rel_obj_doc = ActiveFedora::SolrService.query("id:#{id}", :defType => "edismax")
        unless rel_obj_doc.empty?
          link_text = rel_obj_doc[0][ActiveFedora::SolrQueryBuilder.solr_name('title', :stored_searchable, type: :string)].first
          item_array.to_a.push [link_text, rel_obj_doc[0]["id"]]
        end
      end
      rels["#{display_label}"] = Kaminari.paginate_array(item_array).page(params[display_label.downcase.gsub(/\s/,'_') << "_page"]).per(4) unless item_array.empty?
    end # each

    rels
  end

  def relationships_records
    records = {}

    object_class = self.active_fedora_model.constantize
    relationships = object_class.relationships

    relationships.each { |key, value| records[key] = retrieve_relation_records(self.object_profile[value[:field]], object_class.solr_relationships_field)}

    records
  end

  def retrieve_relation_records rels_array, solr_id_field
    records = []

    # Get Root collection of current object.
    root = root_collection

    if (root)
      rels_array.each do |item_id|
        # We need to index the identifier element value to be able to search in Solr and then retrieve the document by id
        solr_query = "#{solr_id_field}:\"#{item_id.to_s}\""
        solr_query << " AND #{ActiveFedora::SolrQueryBuilder.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root.id}\""
        solr_results = ActiveFedora::SolrService.query(solr_query, :defType => "edismax")

        if solr_results.present?
          solr_results.each do |item|
            doc = SolrDocument.new(item)
            records << doc.id
          end
        else
          Rails.logger.error("Relationship target object #{item_id} not found in Solr for object #{self.id}")
        end
      end
    else
      Rails.logger.error("Root collection ID for object with PID #{self.id} not found in Solr")
    end
   
    records
  end # end retrieve_rela

end