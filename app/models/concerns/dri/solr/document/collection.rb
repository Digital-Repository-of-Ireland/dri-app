module DRI::Solr::Document::Collection
  # Filter to only get those that are collections:
  # fq=is_collection_tesim:true
  def children(limit: 100)
    # Find immediate children of this collection
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{id}\""
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    q_result = Solr::Query.new(solr_query, limit, fq: f_query)
    q_result.to_a
  end

  def cover_image
    cover_field = ActiveFedora.index_field_mapper.solr_name('cover_image', :stored_searchable, type: :string)
    self[cover_field] && self[cover_field][0] ? self[cover_field][0] : nil
  end

  def draft_objects
    status_count('draft')
  end

  def draft_subcollections
    status_count('draft', true)
  end

  def published_objects
    status_count('published')
  end

  def published_subcollections
    status_count('published', true)
  end

  def reviewed_objects
    status_count('reviewed')
  end

  def reviewed_subcollections
    status_count('reviewed', true)
  end

  def total_objects
    status_count(nil)
  end

  def duplicate_total
    response = duplicate_query

    duplicates = response['facet_counts']['facet_fields']["#{metadata_field}"]

    total = 0
    duplicates.each_slice(2) { |duplicate| total += duplicate[1].to_i }

    total
  end

  def duplicates
    response = duplicate_query

    ids = []
    duplicates = response['facet_counts']['facet_pivot']["#{metadata_field},id"].select { |f| f['count'] > 1 }
    duplicates.each do |dup|
      pivot = dup["pivot"]
      pivot.each { |p| ids << p['value'] }
    end

    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
    response = ActiveFedora::SolrService.get(query, rows: ids.size)

    docs = response['response']['docs']
    duplicates = []
    docs.each { |d| duplicates << SolrDocument.new(d) }

    return Blacklight::Solr::Response.new(response['response'], response['responseHeader']), duplicates
  end

  private

    def metadata_field
      ActiveFedora.index_field_mapper.solr_name('metadata_md5', :stored_searchable, type: :string)
    end

    def status_count(status, subcoll = false)
      query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{id}"
      query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:#{status}" unless status.nil?
      query += " AND #{ActiveFedora.index_field_mapper.solr_name('is_collection', :searchable, type: :symbol)}:#{subcoll}"

      ActiveFedora::SolrService.count(query)
    end

    def duplicate_query
      query_params = {
        fq: [
          "+#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{id}",
          "+has_model_ssim:\"DRI::Batch\"", "+is_collection_sim:false"
        ],
        "facet.pivot" => "#{metadata_field},id",
        facet: true,
        "facet.mincount" => 2,
        "facet.field" => "#{metadata_field}"
      }

      ActiveFedora::SolrService.get('*:*', query_params)
    end
end
