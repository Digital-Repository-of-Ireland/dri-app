module DRI::Solr::Document::Collection

  def draft_objects
    ActiveFedora::SolrService.count("#{ActiveFedora::SolrQueryBuilder.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id} AND #{ActiveFedora::SolrQueryBuilder.solr_name('status', :stored_searchable, type: :symbol)}:draft")
  end


end
