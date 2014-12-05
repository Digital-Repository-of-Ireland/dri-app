class ReindexSolrJob

  def queue_name
    :reindex
  end

  def run
    GenericFile.find_each { |obj| obj.update_index }
    Batch.find_each { |obj| obj.update_index }
  end

end
