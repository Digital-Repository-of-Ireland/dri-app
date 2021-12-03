# frozen_string_literal: true
class FixityJob
  extend Preservation::PreservationHelpers

  @queue = :fixity

  def self.perform(report_id, root_collection_id, collection_id)
    Rails.logger.info "Verifying collection #{collection_id}"

    # query for objects within this collection
    q_str = "collection_id_sim:\"#{collection_id}\""
    # excluding sub-collections
    f_query = "is_collection_ssi:false"

    fixity_check(report_id, root_collection_id, q_str, f_query)
  end

  def self.fixity_check(report_id, root_collection_id, q_str, f_query)
    query = Solr::Query.new(q_str, 100, fq: f_query)
    query.each do |o|
      object = DRI::DigitalObject.find_by_alternate_id(o.alternate_id)
      result = Preservation::Preservator.new(object).verify

      FixityCheck.create(
        fixity_report_id: report_id,
        collection_id: root_collection_id,
        object_id: o.alternate_id,
        verified: result[:verified],
        result: result.to_json
      )
    end
  end
end
