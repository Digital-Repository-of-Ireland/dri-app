class CreateBucketJob < ActiveFedoraIdBasedJob
  include BackgroundTasks::Status

  def queue_name
    :create_bucket
  end

  def run
    with_status_update('create_bucket') do
      bucket_id = object.batch.nil? ? object.id : object.batch.id
      Rails.logger.info "Creating bucket for object #{bucket_id}"

      storage = StorageService.new
      created = storage.create_bucket(bucket_id)
      
      raise "Unable to create storage bucket" unless created

      after_create_bucket
    end
  end

  # Now that we have a bucket set up, we can now save files into it
  def after_create_bucket
    if generic_file.pdf?
      status_for_type('pdf')
      DRI.queue.push(ThumbnailJob.new(generic_file_id))
      DRI.queue.push(TextSurrogateJob.new(generic_file_id))
    elsif generic_file.text?
      status_for_type('text')
      DRI.queue.push(CreateDerivativesJob.new(generic_file_id))
    elsif generic_file.video?
      status_for_type('video')
      DRI.queue.push(CreateDerivativesJob.new(generic_file_id))
    elsif generic_file.audio?
      status_for_type('audio')
      DRI.queue.push(CreateDerivativesJob.new(generic_file_id))
    elsif generic_file.image?
      status_for_type('image')
      DRI.queue.push(ThumbnailJob.new(generic_file_id))
    end
  end

end
