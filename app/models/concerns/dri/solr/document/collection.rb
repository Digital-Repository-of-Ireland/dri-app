module DRI::Solr::Document::Collection

  def draft_objects
    status_count('draft')
  end

  def published_objects
    status_count('published')
  end

  def reviewed_objects
    status_count('reviewed')
  end

  private

  def status_count(status)
    ActiveFedora::SolrService.count("#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id} 
      AND #{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:#{status}")
  end


end
