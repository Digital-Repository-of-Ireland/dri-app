class CharacterizeJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :characterize
  end

  def run
    with_status_update('characterize') do
      status_for_type('preservation') if generic_file.preservation?
      
      generic_file.characterize
      generic_file.save

      after_characterize
    end
  end

  def after_characterize
    unless generic_file.preservation_only == 'true'
      Sufia.queue.push(CreateBucketJob.new(generic_file_id))
    end

    # Update the Batch object's Solr index now that the GenericFile
    # has characterization metadata
    unless generic_file.batch.nil?
      Sufia.queue.push(UpdateIndexJob.new(generic_file.batch.id))
    end
  end
end
