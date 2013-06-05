module S3Interface
  module Utils

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
          file.match(/dri:#{bucket}-([-a-zA-z0-9]*)\..*/)
          url = AWS::S3::S3Object.url_for(file, bucket, :authenticated => true, :expires_in => 60 * 30)
          @surrogates_hash[$1] = url
        rescue AWS::S3::ResponseError, AWS::S3::S3Exception => e
          logger.debug "Problem getting url for file #{filename} : #{e.to_s}"
        end
      end

      AWS::S3::Base.disconnect!()

      return @surrogates_hash
    end
  end

end
