module DRI::Solr::Document::Relations
  # Returns an Array with all the URLS of related materials for UI Display
  # @return Array external related materials
  #
  def external_relationships
    url_array = []

    solr_fields_array = external_relationships_solr_fields if active_fedora_model

    if solr_fields_array
      solr_fields_array.each do |elem|
        key = Solr::SchemaFields.searchable_string(elem)

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

    if active_fedora_model == 'DRI::Documentation'
      documentation = documentation_for

      if documentation
        link_text = documentation['title_tesim'].first
        relationships_hash['Is Documentation For'] = [[link_text, documentation]]
      end
    else
      relationships_hash.merge!(relationships_for_display) unless %w(DRI::EadComponent DRI::EadCollection).include?(active_fedora_model)
      relationships_hash.merge!(documentation_for_display)
    end

    relationships_hash
  end # object_relationships

  # Format object relationships for json api
  # @return [Array] of Hashes
  def object_relationships_as_json
    relationships = object_relationships
    json = []
    relationships.each do |relationship_type, list_of_objects|
      key = relationship_type.gsub(/\s+/, '') # no spaces in json keys
      solr_docs = list_of_objects.flatten.select { |v| v.kind_of? SolrDocument }
      solr_docs.each do |doc|
        url = Rails.application.routes.url_helpers.url_for({controller: 'catalog', action: 'show', id: doc.id})
        json << {
          relation: key,
          # if doi exists serialize it, otherwise return nil
          doi: DRI::Formatters::Json.dois(doc),
          url: url
        }
      end
    end
    json
  end

  private

    def documentation_for_display
      docs = {}
      doc_array = []

      documentation_ids = documentation_object_ids
      documentation_ids.each do |id|
        solr_doc = SolrDocument.find(id)
        next if solr_doc.nil?

        link_text = solr_doc['title_tesim'].first
        doc_array.to_a.push [link_text, solr_doc]
      end
      docs['Has Documentation'] = doc_array unless doc_array.empty?

      docs
    end

    def relationships_for_display
      rels = {}

      relationships_with_documents.each do |rel, docs|
        display_label = active_fedora_model.constantize.relationships[rel][:label]
        item_array = []

        docs.each do |rel_obj_doc|
          link_text = rel_obj_doc['title_tesim'].first
          item_array.to_a.push [link_text, rel_obj_doc]
        end

        rels["#{display_label}"] = item_array unless item_array.empty?
      end # each

      rels
    end

    def relationships_with_documents
      records = {}

      object_class = active_fedora_model.constantize
      relationships = object_class.relationships

      relationships.each do |key, value|
        relations_array = self["#{value[:field]}_tesim"]
        records[key] = relation_solr_documents(
                         relations_array,
                         object_class.solr_relationships_field
                       ) unless relations_array.blank?
      end

      records
    end

    def relation_solr_documents(relations_array, solr_id_field)
      solr_documents = []

      # Get Root collection of current object.
      root = root_collection
      relatives_ids = [root.relatives << root.id].uniq

      unless root
        Rails.logger.error("Root collection ID for object with PID #{id} not found in Solr")
        return records
      end

      solr_query = "#{solr_id_field}:(#{relations_array.map { |r| "\"#{r}\"" }.join(' OR ')})"
      solr_query << " AND root_collection_id_ssi:(\"#{relatives_ids}\")"

      response = Solr::Query.new(
                  solr_query,
                  100,
                  { rows: relations_array.length, defType: 'edismax'}
                ).get

      unless response.documents.present?
        Rails.logger.error("Relationship target objects not found in Solr for object #{id}")
      end

      response.documents
    end

    def external_relationships_solr_fields
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
