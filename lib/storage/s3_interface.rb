module Storage
  module S3Interface

    # Return the best available surrogate for delivery
    def self.deliverable_surrogate?(doc, list = nil)

      deliverable_surrogate = nil
      deliverable_surrogates = []

      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                          :access_key_id => Settings.S3.access_key_id,
                                          :secret_access_key => Settings.S3.secret_access_key)
      bucket = doc.id.sub('dri:', '')
      object_type = doc["type_tesim"][0]
      files = []
      begin
        bucketobj = AWS::S3::Bucket.find(bucket)
        bucketobj.each do |fileobj|
          files << fileobj.key
        end
      rescue
        logger.debug "Problem listing files in bucket #{bucket}"
        AWS::S3::Base.disconnect!()
      end

      if list == nil
        unless Settings.surrogates[object_type.camelcase.to_sym].nil?
          Settings.surrogates[object_type.camelcase.to_sym].each do |surrogate_type|
            filename = "dri:#{bucket}_#{surrogate_type}"
            deliverable_surrogate = files.find { |e| /#{filename}/ =~ e }
            break unless deliverable_surrogate.nil?
          end
        end
        AWS::S3::Base.disconnect!()
        return deliverable_surrogate
      else
        unless Settings.surrogates[object_type.camelcase.to_sym].nil?
          Settings.surrogates[object_type.camelcase.to_sym].each do |surrogate_type|
            filename = "dri:#{bucket}_#{surrogate_type}"
            deliverable_surrogates << files.find { |e| /#{filename}/ =~ e }
          end
        end
        AWS::S3::Base.disconnect!()
        return deliverable_surrogates
      end

    end

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

    # Save Surrogate File
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


    # Save arbitrary file
    def self.store_file(file, filename, bucket)
      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                         :access_key_id => Settings.S3.access_key_id,
                                         :secret_access_key => Settings.S3.secret_access_key)

      begin
        AWS::S3::S3Object.store(filename, open(file), bucket, :access => :public_read)
      rescue Exception => e
        logger.error "Problem saving file #{filename} : #{e.to_s}"
        raise
      end
      AWS::S3::Base.disconnect!()
    end


    # Get link for arbitrary file
    def self.get_link_for_surrogate(bucket, file)
      AWS::S3::Base.establish_connection!(:server => Settings.S3.server,
                                         :access_key_id => Settings.S3.access_key_id,
                                         :secret_access_key => Settings.S3.secret_access_key)

      begin
        url = AWS::S3::S3Object.url_for(file, bucket, :authenticated => false)
      rescue Exception => e
        logger.error "Problem getting link for file #{file} : #{e.to_s}"
      end
      AWS::S3::Base.disconnect!()
      return url
    end


  end

end
