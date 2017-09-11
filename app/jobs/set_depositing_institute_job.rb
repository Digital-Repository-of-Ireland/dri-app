class SetDepositingInstituteJob < ActiveFedoraIdBasedJob

  def queue_name
    :set_depositing_institute
  end

  def run
    Rails.logger.info "Setting depositing institute for sub-collections in #{object.noid}"

    query = "#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.noid}\""
    fq = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"
    query_results = Solr::Query.new(query, 100, :fq => fq)

    while query_results.has_more?
      subcollections = query_results.pop

      subcollections.each do |col|
        ident = DRI::Identifier.find_by!(alternate_id: col['id'])
        col_obj = ident.identifiable
        col_obj.depositing_institute = object.depositing_institute
        col_obj.save

        DRI.queue.push(SetDepositingInstituteJob.new(col_obj.noid)) unless col_obj.governed_items.blank?
      end
    end

  end

end
