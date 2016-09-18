module DRI::Solr::Document::Documentation
  def documentation_object_ids
    @documentation_object_ids ||= retrieve_document_ids
  end

  def documentation_for
    @documentation_for ||= retrieve_documentation_for
  end

  private

    def retrieve_documentation_for
      key = ActiveFedora.index_field_mapper.solr_name('isDescriptionOf', :stored_searchable, type: :symbol)
      return nil unless self[key].present?

      results = ActiveFedora::SolrService.query("id:#{self[key].first}")
      results.present? ? SolrDocument.new(results.first) : nil
    end

    def retrieve_document_ids
      key = ActiveFedora.index_field_mapper.solr_name('isDescriptionOf', :stored_searchable, type: :symbol)
      ids = ActiveFedora::SolrService.query("#{key}:\"#{id}\"", fl: 'id')
      ids.map(&:values).flatten
    end
end
