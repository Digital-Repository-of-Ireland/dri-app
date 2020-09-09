module DRI::Solr::Document::Collection

  def descendants(limit: 100)
    # Find all sub-collections below this collection
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :stored_searchable, type: :string)}:\"#{self.id}\""
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    q_result = Solr::Query.new(solr_query, limit, fq: f_query)
    q_result.to_a
  end

  # Filter to only get those that are collections:
  # fq=is_collection_tesim:true
  def children(limit: 100)
    # Find immediate children of this collection
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :stored_searchable, type: :string)}:\"#{self.id}\""
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:true"

    q_result = Solr::Query.new(solr_query, limit, {fq: f_query, sort: "system_create_dtsi asc"})
    q_result.to_a
  end

  def cover_image
    cover_field = ActiveFedora.index_field_mapper.solr_name('cover_image', :stored_searchable, type: :string)
    self[cover_field] && self[cover_field][0] ? self[cover_field][0] : nil
  end

  def draft_objects_count
    status_count('draft')
  end

  def draft_subcollections_count
    status_count('draft', true)
  end

  def published_objects_count
    status_count('published')
  end

  def published_object_ids
    status_ids('published')
  end

  def published_objects
    status_objects('published')
  end

  def published_images
    published_objects.select do |doc|
      doc.file_type_label == 'Image'
    end
  end

  def published_subcollections_count
    status_count('published', true)
  end

  def reviewed_objects_count
    status_count('reviewed')
  end

  def reviewed_subcollections_count
    status_count('reviewed', true)
  end

  def total_objects_count
    status_count(nil)
  end

  def duplicate_total
    response = duplicate_query

    duplicates = response['facet_counts']['facet_pivot']['metadata_md5_tesim,id'].select { |value| value['count'] > 1 && value['pivot'].present? }
    total = 0
    duplicates.each { |duplicate| total += duplicate['count'] }

    total
  end

  def duplicates(sort=nil)
    response = duplicate_query

    ids = []
    duplicates = response['facet_counts']['facet_pivot']["#{metadata_field},id"].select { |f| f['count'] > 1 }
    duplicates.each do |duplicate|
      pivot = duplicate["pivot"]
      next unless pivot
      pivot.each { |p| ids << p['value'] }
    end

    query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
    response = ActiveFedora::SolrService.get(query, sort: sort, rows: ids.size)

    docs = response['response']['docs']
    duplicate_docs = docs.collect { |d| SolrDocument.new(d) }

    return Blacklight::Solr::Response.new(response['response'], response['responseHeader']), duplicate_docs
  end

  # @param [String] type
  # @param [Boolean] published_only
  # @return [Integer]
  def type_count(type, published_only: false)
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"" + self.id +
                 "\" AND " +
                 "#{ActiveFedora.index_field_mapper.solr_name('file_type_display', :facetable, type: :string)}:"+ type
    if published_only
      solr_query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end
    ActiveFedora::SolrService.count(solr_query, defType: 'edismax')
  end
   
   def type_count_3d(type, published_only: false)
    solr_query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:\"" + self.id +
                 "\" AND " +
                 "#{ActiveFedora.index_field_mapper.solr_name('type', :facetable, type: :string)}:"+ type

    if published_only
      solr_query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end
    ActiveFedora::SolrService.count(solr_query, defType: 'edismax')
  end 


  private

    def metadata_field
      ActiveFedora.index_field_mapper.solr_name('metadata_md5', :stored_searchable, type: :string)
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [String] solr query for children of self (id) with given status
    def status_query(status, subcoll = false)
      query = "#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id}"
      query += " AND #{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:#{status}" unless status.nil?
      query += " AND #{ActiveFedora.index_field_mapper.solr_name('is_collection', :searchable, type: :symbol)}:#{subcoll}"
      query
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [Integer]
    def status_count(status, subcoll = false)
      ActiveFedora::SolrService.count(status_query(status, subcoll))
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [Solr::Query]
    def status_objects(status, subcoll = false)
      Solr::Query.new(status_query(status, subcoll))
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [Array] List of IDs
    def status_ids(status, subcoll = false)
      Solr::Query.new(status_query(status, subcoll)).map(&:id)
    end

    def duplicate_query
      query_params = {
        fq: [
          "+#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id}",
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
