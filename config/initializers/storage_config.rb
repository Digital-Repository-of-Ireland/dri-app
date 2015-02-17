
credentials = Aws::Credentials.new(Settings.S3.access_key_id, Settings.S3.secret_access_key)
client = Aws::S3::Client.new(region: 'us-east-1', endpoint: Settings.S3.server, credentials: credentials, ssl_verify_peer: false, force_path_style: true)
s3 = Aws::S3::Resource.new(client: client)

buckets = s3.buckets.entries.map(&:name)

if Settings.data.cover_image_bucket.blank?
  Rails.logger.error "Storage bucket for cover images not configured"
else
  bucket = Settings.data.cover_image_bucket
  begin
    unless buckets.includes?(bucket)
      begin
        s3.create_bucket(bucket: bucket)
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      s3.create_bucket(bucket: bucket)
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
    unless buckets.includes?(bucket)
      begin
        s3.create_bucket(bucket: bucket)
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  rescue
    begin
      s3.create_bucket(bucket: bucket)
    rescue Exception => e
      Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
    end
  end
end
