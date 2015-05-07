class ReindexSolrJob

  def queue_name
    :reindex
  end

  def run
    DRI::GenericFile.find_each { |obj| obj.update_index }
    # Cast needed as the objects need to be loaded with the sub-class model (for relationships)
    # i.e. DRI::QualifiedDublinCore, or DRI::Mods as opposed to simply DRI::Batch
    DRI::Batch.find_each({}, {:cast => true}) { |obj| obj.update_index }
  end

end
