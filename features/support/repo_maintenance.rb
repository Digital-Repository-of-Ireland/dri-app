module RepoMaintenance


  def clean_repo
    fedora_objects = ActiveFedora::Base.all
    fedora_objects.each do |object|
      object.delete
    end
  end

  def clean_s3
    AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                        :access_key_id => Settings.S3.access_key_id,
                                        :secret_access_key => Settings.S3.secret_access_key)
    AWS::S3::Service.buckets.each do |bucket|
      bucket.each do |file|
        AWS::S3::S3Object.delete(file.key, bucket.name)
      end
      AWS::S3::Bucket.delete(bucket.name, :force => true)
    end
    AWS::S3::Base.disconnect!()
  end

end
World(RepoMaintenance)
