class CreateBucketJob < ActiveFedoraPidBasedJob

  require 'storage/s3_interface'

  def queue_name
    :create_bucket
  end

  def run
    Rails.logger.info "Creating bucket for object #{generic_file_id}"
    Storage::S3Interface.create_bucket(generic_file_id.sub('dri:', ''))
    after_create_bucket
  end

  # Now that we have a bucket set up, we can now save files into it
  def after_create_bucket

    #if generic_file.pdf? || generic_file.image? || generic_file.video?
    #  generic_file.create_thumbnail
    #end

    if generic_file.pdf?
      Sufia.queue.push(IndexTextJob.new(generic_file_id))
    elsif generic_file.video?
      Sufia.queue.push(TranscodeVideoJob.new(generic_file_id))
    elsif generic_file.audio?
      Sufia.queue.push(TranscodeAudioJob.new(generic_file_id))
    end
  end
end