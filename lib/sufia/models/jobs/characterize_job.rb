class CharacterizeJob < ActiveFedoraPidBasedJob

  def queue_name
    :characterize
  end

  def run
    generic_file.characterize
    after_characterize
  end

  def after_characterize
    Sufia.queue.push(CreateChecksumsJob.new(generic_file_id))
    Sufia.queue.push(CreateBucketJob.new(generic_file_id))
  end

end