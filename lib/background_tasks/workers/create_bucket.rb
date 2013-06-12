class CreateBucket
  @queue = "create_bucket_queue"

  require 'storage/s3_interface'

  def self.perform(object_id)
    Rails.logger.info "Creating bucket for object #{object_id}"

    Storage::S3Interface.create_bucket(object_id.sub('dri:', ''))

  end

end
