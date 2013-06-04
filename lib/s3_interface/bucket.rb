module S3Interface
  class Bucket
    def create_bucket(bucket)

      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)
      begin
        AWS::S3::Bucket.create(bucket)
      rescue AWS::S3::ResponseError, AWS::S3::S3Exception => e
        logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        raise Exceptions::InternalError
      end
      AWS::S3::Base.disconnect!()
    end

  end

end
