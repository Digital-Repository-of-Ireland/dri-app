module DRI::Solr::Document::Relations
  # Returns an Array with all the URLS of related materials for UI Display
  # @return Array external related materials
  #
  def external_relationships
    url_array = []

    solr_fields_array = solr_fields_for_standard if active_fedora_model

    if solr_fields_array
      solr_fields_array.each do |elem|
        key = ActiveFedora.index_field_mapper.solr_name(elem, :stored_searchable, type: :string)

        url_array = url_array.to_a.push(*self[key]) if self[key].present?
      end
    end

    url_array
  end

  # Returns a Hash with relationship groups and generated links to related objects
  # for UI Display
  # @return Hash related items grouped by type of relationship
  #
  def object_relationships
    relationships_hash = {}

    begin

      if active_fedora_model == 'DRI::Documentation'
        documentation = documentation_for

        if documentation
          link_text = documentation[ActiveFedora.index_field_mapper.solr_name('title')].first
          relationships_hash['Is Documentation For'] = [[link_text, documentation]]
        end
      else
        relationships_hash.merge!(get_relationships) unless active_fedora_model == 'DRI::EncodedArchivalDescription'
        relationships_hash.merge!(get_documentation)
      end

    rescue ActiveFedora::ObjectNotFoundError
      Rails.logger.error("Object not found: #{document['id']}")
    end

    relationships_hash
  end # get_object_relationships

  private

    def get_documentation
      docs = {}
      doc_array = []

      documentation_ids = documentation_object_ids
      documentation_ids.each do |id|
        doc_obj = ActiveFedora::SolrService.query("id:#{id}", defType: 'edismax')
        next if doc_obj.empty?

        solr_doc = SolrDocument.new(doc_obj[0])

        link_text = solr_doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)].first
        doc_array.to_a.push [link_text, solr_doc]
      end
      docs['Has Documentation'] = doc_array unless doc_array.empty?

      docs
    end

    def get_relationships
      rels = {}

      relationships_records.each do |rel, value|
        display_label = active_fedora_model.constantize.relationships[rel][:label]
        item_array = []

        value.each do |rel_obj_doc|
          link_text = rel_obj_doc[ActiveFedora.index_field_mapper.solr_name('title', :stored_searchable, type: :string)].first
          item_array.to_a.push [link_text, rel_obj_doc]
        end

        rels["#{display_label}"] = item_array unless item_array.empty?
      end # each

      rels
    end

    def relationships_records
      records = {}

      object_class = active_fedora_model.constantize
      relationships = object_class.relationships

      relationships.each do |key, value|
        relations_array = object_profile[value[:field]]
        records[key] = retrieve_relation_records(relations_array, object_class.solr_relationships_field) unless relations_array.blank?
      end

      records
    end

    def retrieve_relation_records(relations_array, solr_id_field)
      records = []

      # Get Root collection of current object.
      root = root_collection

      if root
        solr_query = "#{solr_id_field}:(#{relations_array.map { |r| "\"#{r}\"" }.join(' OR ')})"
        solr_query << " AND #{ActiveFedora.index_field_mapper.solr_name('root_collection_id', :stored_searchable, type: :string)}:\"#{root.id}\""

        solr_results = ActiveFedora::SolrService.query(solr_query, rows: relations_array.length, defType: 'edismax')

        if solr_results.present?
          solr_results.each { |item| records << SolrDocument.new(item) }
        else
          Rails.logger.error("Relationship target objects not found in Solr for object #{id}")
        end
      else
        Rails.logger.error("Root collection ID for object with PID #{id} not found in Solr")
      end

      records
    end

    def solr_fields_for_standard
      case active_fedora_model
      when 'DRI::Mods'
        solr_field_array = *(DRI::Vocabulary.mods_relationship_types.map { |s| s.prepend('ext_related_items_ids_').to_sym })
      when 'DRI::QualifiedDublinCore'
        solr_field_array = *(DRI::Vocabulary.qdc_relationship_types.map { |s| s.prepend('ext_related_items_ids_').to_sym })
      when 'DRI::Marc', 'DRI::EncodedArchivalDescription'
        solr_field_array = [:related_material, :alternative_form]
      else
        solr_field_array = nil
      end

      solr_field_array
    end
end
