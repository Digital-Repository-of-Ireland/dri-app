class CharacterizeJob < ActiveFedoraIdBasedJob

  def queue_name
    :characterize
  end

  def run
    begin
      generic_file.characterize
      generic_file.save

      after_characterize
    rescue => e
      Rails.logger.error "Unable to characterize file #{generic_file_id}"
    end
  end

  def after_characterize
    unless generic_file.preservation_only.eql?('true')
      Sufia.queue.push(CreateBucketJob.new(generic_file_id))
    end

    # Update the Batch object's Solr index now that the GenericFile
    # has characterization metadata
    unless generic_file.batch.nil?
      Sufia.queue.push(UpdateIndexJob.new(generic_file.batch.id))
    end
  end

end
