class StorageService

  def initialize
    driver_class = "Storage::#{Settings.storage.driver.camelcase}".constantize
    @driver = driver_class.new
  end

  def bucket_exists?(bucket_name)
    @driver.bucket_exists?(bucket_name)
  end
      
  # Create bucket
  def create_bucket(bucket_name)
    @driver.create_bucket(bucket_name)
  end

  def delete_bucket(bucket_name)
    @driver.delete_bucket(bucket_name)
  end

  def delete_surrogates(object_id, file_id)
    @driver.delete_surrogates(object_id, file_id)
  end
  
  def get_surrogates(object, file, expire=nil)
    @driver.get_surrogates(object, file, expire)
  end

  def surrogate_exists?(bucket, key)
    @driver.surrogate_exists?(bucket, key)
  end

  def surrogate_info(bucket, key)
    @driver.surrogate_info(bucket, key)
  end

  def surrogate_url(bucket, key, expire=nil)
    @driver.surrogate_url(bucket, key, expire)
  end

  def store_surrogate(bucket, surrogate_file, surrogate_key)
    @driver.store_surrogate(bucket, surrogate_file, surrogate_key)
  end
         
end
