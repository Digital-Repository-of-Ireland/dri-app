
storage = StorageService.new

begin
  if !Settings.data || Settings.data.cover_image_bucket.nil?
    Rails.logger.error "Storage bucket for cover images not configured"
  else
   Rails.logger.info "Creating bucket"
    bucket = Settings.data.cover_image_bucket
    begin
      unless storage.bucket_exists?(bucket)
        begin
          storage.create_file_bucket(bucket)
        rescue Exception => e
          Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        end
      end
    rescue
      begin
        storage.create_file_bucket(bucket)
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
      end
    end
  end
rescue Exception => e
end
