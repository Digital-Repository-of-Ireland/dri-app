module Storage
  class S3Interface

    def initialize(options = {})
      endpoint = Settings.S3.server
      credentials = Aws::Credentials.new(Settings.S3.access_key_id, Settings.S3.secret_access_key)

      params = options.merge({ region: 'us-east-1', endpoint: endpoint, credentials: credentials, ssl_verify_peer: false, force_path_style: true })
      @client = Aws::S3::Client.new(params)
    end

    def bucket_exists?(bucket)
      @client.head_bucket(bucket: with_prefix(bucket))

      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    # Create bucket
    def create_bucket(bucket)
      @client.create_bucket(bucket: with_prefix(bucket))

      true
    rescue Exception => e
      Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e}"
      false
    end
   
    # Delete bucket
    def delete_bucket(bucket_name)
      return false unless bucket_exists?(bucket_name)

      begin
        objects = list_files(bucket_name)
        objects.each { |obj| @client.delete_object(bucket: with_prefix(bucket_name), key: obj) }
          
        @client.delete_bucket(bucket: with_prefix(bucket_name))
        true
      rescue Exception => e
        Rails.logger.error "Could not delete Storage Bucket #{bucket_name}: #{e}"
        false
      end
    end

    def delete_surrogates(bucket, key)
      objects = list_files(bucket, key)
      objects.each { |obj| @client.delete_object(bucket: with_prefix(bucket), key: obj)}
      true
    rescue Exception => e
      Rails.logger.error "Could not delete surrogate for #{key}: #{e}"
      false
    end

    # Get a hash of all surrogates for an object
    # object - SolrDocument or object ID
    # file = SolrDocument or GenericFile ID
    def get_surrogates(object, file, expire = nil)
      expire = Settings.S3.expiry unless (expire.present? && numeric?(expire))
      bucket = object.respond_to?(:id) ? object.id : object
      generic_file_id = file.respond_to?(:id) ? file.id : file

      surrogate_file_names = list_files(bucket)

      @surrogates_hash = {}
      
      surrogate_file_names.each do |filename|
        begin
          if match = filename_match?(filename, generic_file_id)
            url = create_url(bucket, filename, expire)
            @surrogates_hash[match] = url
          end
        rescue Exception => e
          Rails.logger.debug "Problem getting url for file #{file} : #{e.to_s}"
        end
      end
      
      @surrogates_hash
    end

     # Get url for a specific surrogate
    def surrogate_exists?(bucket, key)
      files = list_files(bucket)
      surrogate = files.find { |e| /#{key}/ =~ e }

      return nil unless surrogate.present?
      
      true
    end
    
    # Get information about surrogates for a generic_file
    def surrogate_info(bucket, key)
      surrogates_hash = {}
      begin
        response = @client.list_objects(bucket: with_prefix(bucket))

        if response.successful?
          response.contents.each do |fileobj|
            surrogates_hash[fileobj.key] = @client.head_object(bucket: with_prefix(bucket), key: fileobj.key) if filename_match?(fileobj.key, key)
          end
        else
          Rails.logger.debug "Problem getting surrogate info for file #{key}"
        end
      rescue Exception => e
        Rails.logger.debug "Problem getting surrogate info for file #{key} : #{e}"
      end

      surrogates_hash
    end

    # Get url for a specific surrogate
    def surrogate_url(bucket, key, expire=nil)
      expire = Settings.S3.expiry unless expire.present? && numeric?(expire)

      files = list_files(bucket)
      surrogate = files.find { |e| /#{key}/ =~ e }

      if surrogate.present?
        begin
          url = create_url(bucket, surrogate, expire)
        rescue Exception => e
          Rails.logger.debug "Problem getting url for file #{surrogate}: #{e}"
        end
      end
 
      url
    end
    
    def file_url(bucket, key)
      create_url(bucket, key, nil, false)
    rescue Exception => e
      Rails.logger.error "Problem getting url for file #{file}: #{e}"
    end

    # Save Surrogate File
    def store_surrogate(bucket, surrogate_file, surrogate_key)
      @client.put_object(
        bucket: with_prefix(bucket),
        body: File.open(Pathname.new(surrogate_file)),
        key: surrogate_key)

      true
    rescue Exception  => e
      Rails.logger.error "Problem saving Surrogate file #{surrogate_key}: #{e}"
      false
    end
        
    # Save arbitrary file
    def store_file(bucket, file, file_key)
      @client.put_object(
        bucket: with_prefix(bucket),
        body: File.open(Pathname.new(file)),
        key: file_key)
      @client.put_object_acl(
        acl: "public-read",
        bucket: with_prefix(bucket),
        key: file_key)

      true
    rescue Exception => e
      Rails.logger.error "Problem saving file #{file_key}: #{e}"
      false
    end

    private

    def bucket_prefix
      Settings.S3.bucket_prefix ? "#{Settings.S3.bucket_prefix}.#{Rails.env}" : nil
    end 
        
    def expiration_timestamp(input)
      input = input.to_int if input.respond_to?(:to_int)
      case input
      when Time then input.to_i
      when DateTime then Time.parse(input.to_s).to_i
      when Integer then (Time.now + input).to_i
      when String then Time.parse(input).to_i
      else (Time.now + 60*60).to_i
      end
    end

    def filename_match?(filename, generic_file_id)
      filename.match(/#{generic_file_id}_([-a-zA-z0-9]*)\..*/)

      $1
    end

    def list_files(bucket, file_prefix = nil)
      options = {}
      options[:bucket] = with_prefix(bucket)
      options[:prefix] = file_prefix if file_prefix

      files = []
      begin
        response = @client.list_objects(options)
        files = response.contents.map(&:key)
      rescue
        Rails.logger.debug "Problem listing files in bucket #{bucket}"
      end

      files
    end

    def with_prefix(bucket)
      bucket_prefix ? "#{bucket_prefix}.#{bucket}" : bucket
    end

    def create_url(bucket, object, expire=nil, authenticated=true)
      return signed_url(with_prefix(bucket), object, expiration_timestamp(expire)) if authenticated

      s3 = Aws::S3::Resource.new(client: @client) 
        
      s3.bucket(with_prefix(bucket)).objects.each do |o|        
        return o.object.public_url if o.key.eql?(object)
      end
    end

    def signed_url(bucket, path, expire_date = nil)
      can_string = "GET\n\n\n#{expire_date}\n/#{bucket}/#{path}"

      signature = URI.encode_www_form_component(Base64.encode64(hmac(Settings.S3.secret_access_key, can_string)).strip)
   
      querystring = "AWSAccessKeyId=#{Settings.S3.access_key_id}&Expires=#{expire_date}&Signature=#{signature}"
      
      endpoint = URI.parse(Settings.S3.server)
      uri_class = endpoint.scheme.eql?("https") ? URI::HTTPS : URI::HTTP
      uri_class.build(host: endpoint.host,
                      port: endpoint.port,
                      path: "/#{bucket}/#{path}",
                      query: querystring).to_s
    end

    # Computes an HMAC digest of the passed string.
    # @param [String] key
    # @param [String] value
    # @param [String] digest ('sha256')
    # @return [String]
    def hmac(key, value, digest = 'sha1')
      OpenSSL::HMAC.digest(OpenSSL::Digest.new(digest), key, value)
    end 
  end
end
