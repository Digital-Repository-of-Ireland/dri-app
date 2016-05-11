class StorageService

  def initialize
    driver_class = "Storage::#{Settings.storage.driver.camelcase}".constantize
    @driver = driver_class.new
  end

  def bucket_exists?(bucket_name)
    @driver.bucket_exists?(bucket_name)
  end
      
  # Create bucket
  def create_bucket(bucket)
    @driver.create_bucket(bucket)
  end

  def delete_bucket(bucket_name)
    @driver.delete_bucket(bucket_name)
  end

  def delete_surrogates(object_id, file_id)
    @driver.delete_surrogates(object_id, file_id)
  end

  def file_url(bucket, file)
    @driver.file_url(bucket, file)
  end

  def get_surrogates(object, file, expire = nil)
    @driver.get_surrogates(object, file, expire = nil)
  end

  def surrogate_info(object_id, file_id)
    @driver.surrogate_info(object_id, file_id)
  end

  def surrogate_url(object_id, file_id, name, expire = nil)
    @driver.surrogate_url(object_id, file_id, name, expire = nil)
  end

  def store_surrogate(object_id, surrogate_file, surrogate_key)
    @driver.store_surrogate(object_id, surrogate_file, surrogate_key)
  end

  def store_file(file, file_key, bucket_name)
    @driver.store_file(file, file_key, bucket_name)
  end
      
end
