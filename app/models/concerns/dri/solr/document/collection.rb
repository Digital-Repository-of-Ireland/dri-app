module DRI::Solr::Document::Collection

  def children(limit)
    children_array = []
    # Find immediate children of this collection
    solr_query = "#{Solrizer.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{self.id}\""
    f_query = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    # Filter to only get those that are collections:
    # fq=is_collection_tesim:true
    q_result = Solr::Query.new(solr_query, limit, fq: f_query)
    q_result.each_solr_document do |doc|
      children_array << doc
    end

    children_array
  end

  def draft_objects
    status_count('draft')
  end

  def published_objects
    status_count('published')
  end

  def reviewed_objects
    status_count('reviewed')
  end

  def duplicate_objects
    find_duplicates
  end

  private

  def status_count(status)
    ActiveFedora::SolrService.count("#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id} 
      AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:#{status}")
  end

  def find_duplicates
    metadata_field = ActiveFedora.index_field_mapper.solr_name('metadata_md5', :stored_searchable, type: :string)

    response = ActiveFedora::SolrService.get('*:*', 
      fq: ["+#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id}", 
        "+has_model_ssim:\"DRI::Batch\"", "+is_collection_sim:false"], 
        "facet.pivot" => "#{metadata_field},id", 
        facet: true, 
        "facet.mincount" => 2, 
        "facet.field" => "#{metadata_field}")

    duplicates = response['facet_counts']['facet_fields']["#{metadata_field}"]
    total = 0
    md5 = []

    duplicates.each_slice(2) do |duplicate|
      total += duplicate[1].to_i
      md5 << duplicate[0]
    end

    query = ''
    query = md5.join(' OR ') if md5.count > 0

    return query, total
  end

end
