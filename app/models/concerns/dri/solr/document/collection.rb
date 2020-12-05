module DRI::Solr::Document::Collection

  def descendants(limit: 100)
    # Find all sub-collections below this collection
    solr_query = "#{Solr::SchemaFields.searchable_string('ancestor_id')}:\"#{self.id}\""
    f_query = "#{Solr::SchemaFields.searchable_string('is_collection')}:true"

    Solr::Query.new(solr_query, limit, fq: f_query).to_a
  end

  # Filter to only get those that are collections:
  # fq=is_collection_tesim:true
  def children(limit: 100)
    # Find immediate children of this collection
    solr_query = "#{Solr::SchemaFields.searchable_string('collection_id')}:\"#{self.id}\""
    f_query = "#{Solr::SchemaFields.searchable_string('is_collection')}:true"

    Solr::Query.new(
      solr_query,
      limit,
      {fq: f_query, sort: "system_create_dtsi asc"}
    ).to_a
  end

  def cover_image
    cover_field = Solr::SchemaFields.searchable_string('cover_image')
    self[cover_field] && self[cover_field][0] ? self[cover_field][0] : nil
  end

  def draft_objects_count
    status_counts[:draft_objects]
  end

  def draft_subcollections_count
    status_counts[:draft_collections]
  end

  def published_objects_count
    status_counts[:published_objects]
  end

  def published_object_ids
    status_ids('published')
  end

  def published_objects
    status_objects('published')
  end

  def published_images
    published_objects.select do |doc|
      doc.file_types.any? { |type| type.downcase == 'image' }
    end
  end

  def published_subcollections_count
    status_counts[:published_collections]
  end

  def reviewed_objects_count
    status_counts[:reviewed_objects]
  end

  def reviewed_subcollections_count
    status_counts[:reviewed_collections]
  end

  def total_objects_count
    status_counts[:total_objects]
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

    query = Solr::Query.construct_query_for_ids(ids)
    response = Solr::Query.new(query, 100, { sort: sort, rows: ids.size }).get

    return Blacklight::Solr::Response.new(response.response, response.header), response.docs
  end

  def file_display_type_count(published_only: false)
    fq = [
          "+#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id}",
          "+has_model_ssim:\"DRI::Batch\"", "+is_collection_sim:false"
        ]

    if published_only
       fq << "+#{ActiveFedora.index_field_mapper.solr_name('status', :stored_searchable, type: :symbol)}:published"
    end

     query_params = {
        fq: fq,
        facet: true,
        "facet.mincount" => 1,
        "facet.field" => "#{ActiveFedora.index_field_mapper.solr_name('file_type_display', :facetable, type: :string)}"
      }
    response = ActiveFedora::SolrService.get('*:*', query_params)
    counts = Hash[*response['facet_counts']['facet_fields']['file_type_display_sim']]
    counts['all'] = response['response']['numFound'].to_i

    counts
  end

  # @param [String] type
  # @param [Boolean] published_only
  # @return [Integer]
  def type_count(type, published_only: false)
    solr_query = "#{Solr::SchemaFields.facet('ancestor_id')}:\"" + self.id +
                 "\" AND " +
                 "#{Solr::SchemaFields.searchable_string('file_type_display')}:"+ type
    if published_only
      solr_query += " AND #{Solr::SchemaFields.searchable_symbol('status')}:published"
    end
    Solr::Query.new(solr_query).count
  end

  private

    def metadata_field
      Solr::SchemaFields.searchable_string('metadata_md5')
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [String] solr query for children of self (id) with given status
    def status_query(status, subcoll = false)
      query = "#{Solr::SchemaFields.facet('ancestor_id')}:#{self.id}"
      query += " AND #{Solr::SchemaFields.searchable_symbol('status')}:#{status}" unless status.nil?
      query += " AND is_collection_sim:#{subcoll}"
      query
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [Integer]
    def status_count(status, subcoll = false)
      Solr::Query.new(status_query(status, subcoll)).count
    end

    def status_counts
      return @status_counts unless @status_counts.blank?

      fq = [
          "+#{ActiveFedora.index_field_mapper.solr_name('ancestor_id', :facetable, type: :string)}:#{self.id}",
        ]

      query_params = {
        fq: fq,
        facet: true,
        "facet.mincount" => 1,
        "facet.query" => [
                          "status_ssim:published AND is_collection_sim:false",
                          "status_ssim:draft AND is_collection_sim:false",
                          "status_ssim:reviewed AND is_collection_sim:false",
                          "status_ssim:reviewed AND is_collection_sim:true",
                          "status_ssim:draft AND is_collection_sim:true",
                          "status_ssim:published AND is_collection_sim:true",
                          "is_collection_sim:false"
                        ]
      }
      response = ActiveFedora::SolrService.get('*:*', query_params)
      counts = response['facet_counts']['facet_queries']

      @status_counts = {}
      @status_counts[:published_objects] = counts['status_ssim:published AND is_collection_sim:false']
      @status_counts[:reviewed_objects] = counts['status_ssim:reviewed AND is_collection_sim:false']
      @status_counts[:draft_objects] = counts['status_ssim:draft AND is_collection_sim:false']
      @status_counts[:published_collections] = counts['status_ssim:published AND is_collection_sim:true']
      @status_counts[:reviewed_collections] = counts['status_ssim:reviewed AND is_collection_sim:true']
      @status_counts[:draft_collections] = counts['status_ssim:draft AND is_collection_sim:true']
      @status_counts[:total_objects] = @status_counts[:published_objects] + @status_counts[:reviewed_objects] + @status_counts[:draft_objects]

      @status_counts
    end

    # @param [String] status
    # @param [Boolean] subcoll
    # @return [Solr::Query]
    def status_objects(status, subcoll = false)
      Solr::Query.new(status_query(status, subcoll)).to_a
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
          "+#{Solr::SchemaFields.facet('ancestor_id')}:#{id}",
          "+has_model_ssim:\"DRI::DigitalObject\"", "+is_collection_sim:false"
        ],
        "facet.pivot" => "#{metadata_field},id",
        facet: true,
        "facet.mincount" => 2,
        "facet.field" => "#{metadata_field}"
      }

      Solr::Query.new('*:*', 100, query_params).get
    end
end
