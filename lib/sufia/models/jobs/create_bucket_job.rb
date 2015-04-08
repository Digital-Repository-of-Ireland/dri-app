class CreateBucketJob < ActiveFedoraPidBasedJob

  require 'storage/s3_interface'
  require 'utils'

  def queue_name
    :create_bucket
  end

  def run
    bucket_id = object.batch.nil? ? object.id : object.batch.id
    Rails.logger.info "Creating bucket for object #{bucket_id}"

    storage = Storage::S3Interface.new
    storage.create_bucket(Utils.split_id(bucket_id))

    after_create_bucket
  end

  # Now that we have a bucket set up, we can now save files into it
  def after_create_bucket
    if generic_file.pdf?
      #Sufia.queue.push(IndexTextJob.new(generic_file_id))
      Sufia.queue.push(ThumbnailJob.new(generic_file_id))
      Sufia.queue.push(TextSurrogateJob.new(generic_file_id))
    elsif generic_file.text?
      #Sufia.queue.push(IndexTextJob.new(generic_file_id))
      Sufia.queue.push(TextSurrogateJob.new(generic_file_id))
    elsif generic_file.video?
      Sufia.queue.push(CreateDerivativesJob.new(generic_file_id))
    elsif generic_file.audio?
      Sufia.queue.push(CreateDerivativesJob.new(generic_file_id))
    elsif generic_file.image?
      Sufia.queue.push(ThumbnailJob.new(generic_file_id))
    end
  end

end
