class FixityJob
  extend Preservation::PreservationHelpers

  @queue = :fixity

  def self.perform(report_id, collection_id)
    Rails.logger.info "Verifying collection #{collection_id}"

    # query for objects within this collection
    q_str = "#{ActiveFedora.index_field_mapper.solr_name('collection_id', :facetable, type: :string)}:\"#{collection_id}\""

    # excluding sub-collections
    f_query = "#{ActiveFedora.index_field_mapper.solr_name('is_collection', :stored_searchable, type: :string)}:false"

    fixity_check(report_id, collection_id, q_str, f_query)
  end

  def self.fixity_check(report_id, collection_id, q_str, f_query)
    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.each do |o|
      object = DRI::Batch.find(o.id)
      result = Preservation::Preservator.new(object).verify
      puts result.inspect

      FixityCheck.create(
        fixity_report_id: report_id,
        collection_id: object.root_collection.first,
        object_id: object.id,
        verified: result[:verified],
        result: result.to_json
      )
    end
  end
end
