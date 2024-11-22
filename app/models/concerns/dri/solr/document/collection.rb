module DRI::Solr::Document::Collection

  def descendants(chunk: 100)
    # Find all sub-collections below this collection
    solr_query = "ancestor_id_ssim:\"#{self.alternate_id}\""
    f_query = "is_collection_ssi:true"

    Solr::Query.new(solr_query, chunk, fq: f_query).to_a
  end

  # Filter to only get those that are collections:
  # fq=is_collection_ssi:true
  def children(chunk: 100, subcollections_only: true)
    # Find immediate children of this collection
    solr_query = "collection_id_sim:\"#{self.alternate_id}\""
    f_query = "is_collection_ssi:true"

    args = { sort: "system_create_dtsi asc" }
    args[:fq] = f_query if subcollections_only

    Solr::Query.new(
      solr_query,
      chunk,
      args
    ).to_a
  end

  def collection_contains_published_images?
    fq = status_query_filters('published')
    fq << 'file_type_tesim:image'
    Solr::Query.new("ancestor_id_ssim:#{self.alternate_id}", 100, { fq: fq }).count.positive?
  end

  def cover_image
    cover_field = 'cover_image_ss'
    self[cover_field].presence
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
    total = 0
    duplicate_metadata_hashes.each { |_hash, count| total += count }

    total
  end

  def duplicates(sort=nil)
    total = 0
    duplicates = duplicate_metadata_hashes
    duplicates.each { |_hash, count| total += count }

    hashes = duplicates.keys

    query = Solr::Query.construct_query_for_ids(hashes, 'metadata_checksum_ssi')
    response = Solr::Query.new(query, 100, { sort: sort, rows: total }).get

    return Blacklight::Solr::Response.new(response.response, response.header), response.docs
  end

  def duplicate_metadata_hashes
    ids = descendants.map { |descendant| descendant['resource_id_isi']} << self['resource_id_isi']
    DRI::DigitalObject.where(governing_collection_id: ids).group(:metadata_checksum).having('count_metadata_checksum > 1').count(:metadata_checksum)
  end

  def file_display_type_count(published_only: false)
    fq = [
          "+ancestor_id_ssim:#{self.alternate_id}",
          "+has_model_ssim:\"DRI::DigitalObject\"", "+is_collection_ssi:false"
        ]

    if published_only
       fq << "+status_ssi:published"
    end

     query_params = {
        fq: fq,
        facet: true,
        "facet.mincount" => 1,
        "facet.field" => "#{Solrizer.solr_name('file_type_display', :facetable, type: :string)}"
      }
    response = Solr::Query.new('*:*', 100, query_params).get
    counts = Hash[*response['facet_counts']['facet_fields']['file_type_display_sim']]
    counts['all'] = response['response']['numFound'].to_i

    counts
  end

  # @param [String] type
  # @param [Boolean] published_only
  # @return [Integer]
  def type_count(type, published_only: false)
    solr_query = "ancestor_id_ssim:\"" + self.alternate_id +
                 "\" AND " +
                 "#{Solr::SchemaFields.searchable_string('file_type_display')}:"+ type
    if published_only
      Solr::Query.new(solr_query, 100, { fq: 'status_ssi:published' }).count
    else
      Solr::Query.new(solr_query).count
    end
  end

  private

  def metadata_field
    'metadata_checksum_ssi'
  end

  # @param [String] status
  # @param [Boolean] subcoll
  # @return [String] solr query for children of self (id) with given status
  def status_query_filters(status, subcoll = false)
    fq = []
    fq << "status_ssi:#{status}" unless status.nil?
    fq << "is_collection_ssi:#{subcoll}"
    fq
  end

  # @param [String] status
  # @param [Boolean] subcoll
  # @return [Integer]
  def status_count(status, subcoll = false)
    Solr::Query.new(
      "ancestor_id_ssim:#{self.alternate_id}",
      100,
      { fq: status_query_filters(status, subcoll)}
    ).count
  end

  def status_counts
    return @status_counts unless @status_counts.blank?

    fq = [
        "+ancestor_id_ssim:#{self.alternate_id}",
      ]

    query_params = {
      fq: fq,
      facet: true,
      "facet.mincount" => 1,
      "facet.query" => [
                        "status_ssi:published AND is_collection_ssi:false",
                        "status_ssi:draft AND is_collection_ssi:false",
                        "status_ssi:reviewed AND is_collection_ssi:false",
                        "status_ssi:reviewed AND is_collection_ssi:true",
                        "status_ssi:draft AND is_collection_ssi:true",
                        "status_ssi:published AND is_collection_ssi:true",
                        "is_collection_ssi:false"
                      ]
    }
    response = Solr::Query.new('*:*', 100, query_params).get
    counts = response['facet_counts']['facet_queries']

    @status_counts = {}
    @status_counts[:published_objects] = counts['status_ssi:published AND is_collection_ssi:false']
    @status_counts[:reviewed_objects] = counts['status_ssi:reviewed AND is_collection_ssi:false']
    @status_counts[:draft_objects] = counts['status_ssi:draft AND is_collection_ssi:false']
    @status_counts[:published_collections] = counts['status_ssi:published AND is_collection_ssi:true']
    @status_counts[:reviewed_collections] = counts['status_ssi:reviewed AND is_collection_ssi:true']
    @status_counts[:draft_collections] = counts['status_ssi:draft AND is_collection_ssi:true']
    @status_counts[:total_objects] = @status_counts[:published_objects] + @status_counts[:reviewed_objects] + @status_counts[:draft_objects]

    @status_counts
  end

  # @param [String] status
  # @param [Boolean] subcoll
  # @return [Solr::Query]
  def status_objects(status, subcoll = false)
    Solr::Query.new(
      "ancestor_id_ssim:#{self.alternate_id}",
      100,
      { fq: status_query_filters(status, subcoll)}
    )
  end

  # @param [String] status
  # @param [Boolean] subcoll
  # @return [Array] List of IDs
  def status_ids(status, subcoll = false)
    Solr::Query.new(
      "ancestor_id_ssim:#{self.alternate_id}",
      100,
      { fq: status_query_filters(status, subcoll)}
    ).map(&:alternate_id)
  end
end
