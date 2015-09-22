module DRI::Solr::Document::Documentation

  def documentation_object_ids
    @documentation_object_ids ||= retrieve_document_ids
  end

  def documentation_for
    @documentation_for ||= retrieve_documentation_for
  end

  private

  def retrieve_documentation_for
    key = ActiveFedora::SolrQueryBuilder.solr_name('isDescriptionOf', :stored_searchable, type: :symbol)

    if self[key].present?
      results = ActiveFedora::SolrService.query("id:#{self[key].first}")

      results.present? ? SolrDocument.new(results.first) : nil
    else
      nil
    end
  end

  def retrieve_document_ids
    ActiveFedora::SolrService.query("#{ActiveFedora::SolrQueryBuilder.solr_name('isDescriptionOf', :stored_searchable, type: :symbol)}:\"#{self.id}\"", fl: 'id').map(&:values).flatten
  end

end