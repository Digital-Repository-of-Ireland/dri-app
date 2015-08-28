module DRI::Solr::Document::Documentation

  def documentation_object_ids
    ActiveFedora::SolrService.query("#{ActiveFedora::SolrQueryBuilder.solr_name('isDocumentationFor', :stored_searchable, type: :symbol)}:\"#{self.id}\"", fl: 'id').map(&:values).flatten
  end


end