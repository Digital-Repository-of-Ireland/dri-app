
AWS.config(s3_endpoint: Settings.S3.server, :access_key_id => Settings.S3.access_key_id, :secret_access_key => Settings.S3.secret_access_key)
s3 = AWS::S3.new(ssl_verify_peer: false)

if Settings.data.cover_image_bucket.blank?
  Rails.logger.error "Storage bucket for cover images not configured"
else
  bucket = Settings.data.cover_image_bucket
  begin
    unless s3.buckets.exists?(bucket)
      begin
        s3.buckets.create(bucket)
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      s3.buckets.create(bucket)
    rescue Exception => e
      Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
    end
  end
end


if Settings.data.logos_bucket.blank?
  Rails.logger.error "Storage bucket for logos not configured"
else
  bucket = Settings.data.logos_bucket
  begin
    unless s3.buckets.exists?(bucket)
      begin
        s3.buckets.create(bucket)
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      s3.buckets.create(bucket)
    rescue Exception => e
      Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
    end
  end
end
