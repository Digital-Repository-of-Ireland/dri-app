module Storage
  module S3Interface

    # Get a hash of all surrogates for an object
    def self.get_surrogates(doc)

      @object = ActiveFedora::Base.find(doc.id, {:cast => true})

      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)

      bucket = @object.pid.sub('dri:', '')
      files = []
      begin
        bucketobj = AWS::S3::Bucket.find(bucket)
        bucketobj.each do |object|
          files << object.key
        end
      rescue
        logger.debug "Problem listing files in bucket #{bucket}"
      end

      @surrogates_hash = {}
      files.each do |file|
        begin
          file.match(/dri:#{bucket}_([-a-zA-z0-9]*)\..*/)
          url = AWS::S3::S3Object.url_for(file, bucket, :authenticated => true, :expires_in => 60 * 30)
          @surrogates_hash[$1] = url
        rescue Exception => e
          logger.debug "Problem getting url for file #{file} : #{e.to_s}"
        end
      end

      AWS::S3::Base.disconnect!()
      return @surrogates_hash
    end


    # Create bucket
    def self.create_bucket(bucket)
      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)
      begin
        AWS::S3::Bucket.create(bucket)
      rescue Exception => e
        logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        return false
      end
      AWS::S3::Base.disconnect!()
      return true
    end

    # Delete bucket
    def self.delete_bucket(bucket)
      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)
      begin
        AWS::S3::Bucket.delete(bucket, :force => true)
      rescue Exception => e
        logger.error "Could not delete Storage Bucket #{bucket}: #{e.to_s}"
        return false
      end
      AWS::S3::Base.disconnect!()
      return true
    end

    # Save File
    def self.store_surrogate(object_id, outputfile, filename)
      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)
      bucket = object_id.sub('dri:', '')
      begin
       AWS::S3::S3Object.store(filename, open(outputfile), bucket, :access => :public_read)
      rescue Exception  => e
        logger.error "Problem saving Surrogate file #{filename} : #{e.to_s}"
      end
      AWS::S3::Base.disconnect!()
    end


  end

end
