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
    if generic_file.batch != nil
      Sufia.queue.push(UpdateIndexJob.new(generic_file.batch.pid))
    end
  end

end