class SetDepositingInstituteJob < ActiveFedoraIdBasedJob

  def queue_name
    :set_depositing_institute
  end

  def run
    Rails.logger.info "Setting depositing institute for sub-collections in #{object.id}"

    query = "#{Solrizer.solr_name('collection_id', :facetable, type: :string)}:\"#{object.id}\""
    fq = "#{Solrizer.solr_name('is_collection', :stored_searchable, type: :string)}:true"
    query_results = Solr::Query.new(query, 100, :fq => fq)

    while query_results.has_more?
      subcollections = query_results.pop

      subcollections.each do |col|
        col_obj = ActiveFedora::Base.find(col['id'], {:cast => true})
        col_obj.depositing_institute = object.depositing_institute
        col_obj.save

        Sufia.queue.push(SetDepositingInstituteJob.new(col_obj.id)) unless col_obj.governed_items.blank?
      end
    end

  end

end
