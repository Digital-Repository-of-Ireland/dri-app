class CreateBucketJob < ActiveFedoraPidBasedJob

  require 'storage/s3_interface'

  def queue_name
    :create_bucket
  end

  def run
    Rails.logger.info "Creating bucket for object #{pid}"
    Storage::S3Interface.create_bucket(pid.sub('dri:', ''))
    after_create_bucket
  end

  def after_create_bucket
  end
end