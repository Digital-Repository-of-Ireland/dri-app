module Storage
  class S3Interface

    require 'utils'
    include Utils

    def initialize
      endpoint = Settings.S3.server
      
      host_port = endpoint.partition(":")
      @host = host_port[0]
      @port = host_port[2].chomp("/")

      AWS.config(s3_endpoint: endpoint, :access_key_id => Settings.S3.access_key_id, :secret_access_key => Settings.S3.secret_access_key, :s3_force_path_style => true)
      @s3 = AWS::S3.new(ssl_verify_peer: false, use_ssl: Settings.S3.use_ssl)
    end

    # Get a hash of all surrogates for an object
    def get_surrogates(doc, file_doc, expire=nil)

      expire = Settings.S3.expiry unless (!expire.blank? && numeric?(expire))
      bucket = Utils.split_id(doc.id)
      generic_file = Utils.split_id(file_doc.id)

      files = list_files(bucket)
      @surrogates_hash = {}
      files.each do |file|
        begin
          if file.match(/#{Rails.application.config.id_namespace}:#{generic_file}_([-a-zA-z0-9]*)\..*/)
            url = create_url(bucket, file, expire)
            @surrogates_hash[$1] = url
          end
        rescue Exception => e
          logger.debug "Problem getting url for file #{file} : #{e.to_s}"
        end
      end
      return @surrogates_hash
    end


    # Get information about surrogates for a generic_file
    def get_surrogate_info(object_id, file_id)
      bucket = Utils.split_id(object_id)

      surrogates_hash = {}
      begin
        bucketobj = @s3.buckets[bucket]
        bucketobj.objects.each do |fileobj|
          if fileobj.key.match(/#{file_id}_([-a-zA-z0-9]*)\..*/)
            surrogates_hash[fileobj.key] = fileobj.head
          end
        end
      rescue Exception => e
        logger.debug "Problem getting info for file #{file_id} : #{e.to_s}"
      end

      return surrogates_hash
    end


    # Get url for a specific surrogate
    def surrogate_url( object_id, file_id, name, expire=nil )

      expire = Settings.S3.expiry unless (!expire.blank? && numeric?(expire))

      bucket = Utils.split_id(object_id)
      generic_file = Utils.split_id(file_id)
      files = list_files(bucket)

      filename = "#{Rails.application.config.id_namespace}:#{generic_file}_#{name}"
      surrogate = files.find { |e| /#{filename}/ =~ e }

      unless surrogate.blank?
        begin
          url = create_url(bucket, surrogate, expire)
        rescue Exception => e
          logger.debug "Problem getting url for file #{surrogate} : #{e.to_s}"
        end
      end

      return url
    end

    # Create bucket
    def create_bucket(bucket)
      begin
        @s3.buckets.create(bucket)
      rescue Exception => e
        logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        return false
      end
      return true
    end

    # Delete bucket
    def delete_bucket(bucket_name)
      begin
        bucket = @s3.buckets[bucket_name]
        bucket.objects.each do |obj|
          obj.delete
        end
        bucket.delete
      rescue Exception => e
        logger.error "Could not delete Storage Bucket #{bucket}: #{e.to_s}"
        return false
      end
      return true
    end

    # Save Surrogate File
    def store_surrogate(object_id, surrogate_file, surrogate_key)
      bucket_name = Utils.split_id(object_id)
      begin
        bucket = @s3.buckets[bucket_name]
        object = bucket.objects[surrogate_key]
        object.write(Pathname.new(surrogate_file))
      rescue Exception  => e
        logger.error "Problem saving Surrogate file #{surrogate_key} : #{e.to_s}"
      end
    end

    # Save arbitrary file
    def store_file(file, file_key, bucket_name)
      begin
        bucket = @s3.buckets[bucket_name]
        object = bucket.objects[file_key]
        object.write(Pathname.new(file), {:acl => :public_read})

        return true
      rescue Exception => e
        logger.error "Problem saving file #{file_key} : #{e.to_s}"
        
        return false
      end
    end

    # Get an authenticated short-duration url for a file
    def get_link_for_surrogate(bucket, file, expire=nil)
      expire = Settings.S3.expiry unless (!expire.blank? && numeric?(expire))
      begin
        url = create_url(bucket, file, expire)
      rescue Exception => e
        logger.error "Problem getting link for file #{file} : #{e.to_s}"
      end
      return url
    end

    # Get link for arbitrary file
    def get_link_for_file(bucket, file)
      begin
        url = create_url(bucket, file, nil, false)
      rescue Exception => e
        logger.error "Problem getting link for file #{file} : #{e.to_s}"
      end
      return url
    end

    def list_files(bucket)
      files = []
      begin
        bucketobj = @s3.buckets[bucket]
        bucketobj.objects.each do |fileobj|
          files << fileobj.key
        end
      rescue
        logger.debug "Problem listing files in bucket #{bucket}"
      end

      files
    end

  private

    def create_url(bucket, object, expire=nil, authenticated=true)
      bucket_obj = @s3.buckets[bucket]
      object = bucket_obj.objects[object]

      options = { :secure => false, :force_path_style => true }

      unless @port.empty?
        options[:endpoint] = @host
        options[:port] = @port.to_i
      end

      if authenticated
        unless expire.nil?
          object.url_for(:read, options.merge({:expires => expire})).to_s
        else
          object.url_for(:read, options).to_s
        end
      else
        object.public_url(options).to_s
      end
    end

  end
end
