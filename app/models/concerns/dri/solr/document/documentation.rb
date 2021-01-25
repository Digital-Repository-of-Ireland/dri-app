module DRI::Solr::Document::Documentation
  def documentation_object_ids
    @documentation_object_ids ||= retrieve_document_ids
  end

  def documentation_for
    @documentation_for ||= retrieve_documentation_for
  end

  private

    def retrieve_documentation_for
      key = Solr::SchemaFields.searchable_symbol('isDescriptionOf')
      return nil unless self[key].present?

      SolrDocument.find(key)
    end

    def retrieve_document_ids
      ids = Solr::Query.new("isDescriptionOf_ssim:\"#{alternate_id}\"", 100, fl: 'alternate_id')
      ids.map(&:to_h).map(&:values).flatten
    end
end
