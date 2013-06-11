class CreateBucket
  @queue = "create_bucket_queue"

  require 's3_interface/utils'

  def self.perform(object_id)
    Rails.logger.info "Creating bucket for object #{object_id}"

    S3Interface::Utils.create_bucket(object_id.sub('dri:', ''))

  end

end
