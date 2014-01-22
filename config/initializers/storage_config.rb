AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                   :access_key_id => Settings.S3.access_key_id,
                                   :secret_access_key => Settings.S3.secret_access_key)


if Settings.data.cover_image_bucket.blank?
  logger.error "Storage bucket for cover images not configured"
else
  bucket = Settings.data.cover_image_bucket
  begin
    unless AWS::S3::Bucket.find(bucket)
      begin
        AWS::S3::Bucket.create(bucket)
      rescue Exception => e
        logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      AWS::S3::Bucket.create(bucket)
    rescue Exception => e
      logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
    end
  end
end


if Settings.data.logos_bucket.blank?
  logger.error "Storage bucket for logos not configured"
else
#  bucket = Settings.data.logos_bucket
  bucket = "hellothere"
  begin
    unless AWS::S3::Bucket.find(bucket)
      begin
        AWS::S3::Bucket.create(bucket)
      rescue Exception => e
        logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      AWS::S3::Bucket.create(bucket)
    rescue Exception => e
      logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
    end
  end
end

AWS::S3::Base.disconnect!()

