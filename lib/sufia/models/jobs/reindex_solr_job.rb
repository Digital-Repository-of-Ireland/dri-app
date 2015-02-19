class ReindexSolrJob

  def queue_name
    :reindex
  end

  def run
    DRI::GenericFile.find_each { |obj| obj.update_index }
    DRI::Batch.find_each { |obj| obj.update_index }
  end

end
