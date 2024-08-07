class CharacterizeJob < IdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :characterize
  end

  def run
    raise "No file found for id #{id}" if generic_file.nil?

    with_status_update('characterize') do
      status_for_type('preservation') if generic_file.preservation?

      generic_file.characterize
      generic_file.save

      after_characterize
    end
  end

  def after_characterize
    unless generic_file.preservation_only?
      DRI.queue.push(CreateBucketJob.new(generic_file_id))
    end

    # Update the object's Solr index now that the GenericFile
    # has characterization metadata
    unless generic_file.digital_object.nil?
      DRI.queue.push(UpdateIndexJob.new(generic_file.digital_object.alternate_id))
    end
  end
end
