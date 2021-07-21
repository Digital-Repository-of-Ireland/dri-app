class CharacterizeJob < IdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :characterize
  end

  def run
    with_status_update('characterize') do
      status_for_type('preservation') if generic_file.preservation?

      # characterize calls save
      generic_file.characterize

      after_characterize
    end
  end

  def after_characterize
    unless generic_file.preservation_only == 'true'
      DRI.queue.push(CreateBucketJob.new(generic_file_id))
    end

    # Update the object's Solr index now that the GenericFile
    # has characterization metadata
    unless generic_file.digital_object.nil?
      DRI.queue.push(UpdateIndexJob.new(generic_file.digital_object.alternate_id))
    end
  end
end
