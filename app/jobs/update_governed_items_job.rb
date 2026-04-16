class UpdateGovernedItemsJob
  @queue = :update

  def self.perform(collection_id)
    Rails.logger.info "Updating collection #{collection_id}"

    # query for reviewed objects within this collection
    q_str = "collection_id_sim:\"#{collection_id}\""
    # excluding sub-collections
    f_query = "is_collection_ssi:false"

    update_objects(collection_id, q_str, f_query)

    ident = DRI::Identifier.find_by!(alternate_id: collection_id)
    collection = ident.identifiable
    collection.update_index
  end

  def self.update_objects(collection_id, q_str, f_query)
    total_objects = Solr::Query.new(q_str, 100, { fq: f_query }).count

    query = Solr::Query.new(q_str, 100, fq: f_query)
   
    while query.has_more?
      collection_objects = query.pop

      collection_objects.each do |object|
        o = DRI::DigitalObject.find_by_alternate_id(object['alternate_id'])
        o.update_index       
      end
    end
  end
end