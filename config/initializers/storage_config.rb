
credentials = Aws::Credentials.new(Settings.S3.access_key_id, Settings.S3.secret_access_key)
client = Aws::S3::Client.new(region: 'us-east-1', endpoint: Settings.S3.server, credentials: credentials, ssl_verify_peer: false, force_path_style: true)
s3 = Aws::S3::Resource.new(client: client)

buckets = []

def with_prefix(bucket)
  if Settings.S3.bucket_prefix
    "#{Settings.S3.bucket_prefix}.#{Rails.env}.#{bucket}"
  else
    bucket
  end
end

begin
  buckets = s3.buckets.entries.map(&:name)

  if !Settings.data || Settings.data.cover_image_bucket.nil?
    Rails.logger.error "Storage bucket for cover images not configured"
  else
    bucket = Settings.data.cover_image_bucket
    begin
      unless buckets.includes?(with_prefix(bucket))
        begin
          s3.create_bucket(bucket: with_prefix(bucket))
        rescue Exception => e
          Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        end
      end
    rescue
      begin
        s3.create_bucket(bucket: with_prefix(bucket))
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  end

  if !Settings.data || Settings.data.logos_bucket.nil?
    Rails.logger.error "Storage bucket for logos not configured"
  else
    bucket = Settings.data.logos_bucket
    begin
      unless buckets.includes?(with_prefix(bucket))
        begin
          s3.create_bucket(bucket: with_prefix(bucket))
        rescue Exception => e
          Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        end
      end
    rescue
      begin
        s3.create_bucket(bucket: with_prefix(bucket))
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  end

rescue Exception => e
end
