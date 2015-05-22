module Storage
  class S3Interface

    require 'utils'
    include Utils

    def initialize(options={})
      endpoint = Settings.S3.server
      credentials = Aws::Credentials.new(Settings.S3.access_key_id, Settings.S3.secret_access_key)

      params = options.merge({region: 'us-east-1', endpoint: endpoint, credentials: credentials, ssl_verify_peer: false, force_path_style: true})
      @client = Aws::S3::Client.new(params)
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
          Rails.logger.debug "Problem getting url for file #{file} : #{e.to_s}"
        end
      end
      return @surrogates_hash
    end


    # Get information about surrogates for a generic_file
    def get_surrogate_info(object_id, file_id)
      bucket = Utils.split_id(object_id)

      surrogates_hash = {}
      begin
        bucketobj = @client.list_objects(bucket: with_prefix(bucket))
        bucketobj.each do |fileobj|
          if fileobj.key.match(/#{file_id}_([-a-zA-z0-9]*)\..*/)
            surrogates_hash[fileobj.key] = fileobj.head
          end
        end
      rescue Exception => e
        Rails.logger.debug "Problem getting info for file #{file_id} : #{e.to_s}"
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
          Rails.logger.debug "Problem getting url for file #{surrogate}: #{e.to_s}"
        end
      end
 
      return url
    end

    # Create bucket
    def create_bucket(bucket)
      begin
        @client.create_bucket(bucket: with_prefix(bucket))
      rescue Exception => e
        Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e.to_s}"
        return false
      end
      return true
    end

    # Delete bucket
    def delete_bucket(bucket_name)
      begin
        objects = list_files(bucket_name)
        objects.each do |obj|
          obj.delete
        end
        @client.delete_bucket(bucket: with_prefix(bucket_name))
      rescue Exception => e
        Rails.logger.error "Could not delete Storage Bucket #{bucket_name}: #{e.to_s}"
        return false
      end
      return true
    end

    # Save Surrogate File
    def store_surrogate(object_id, surrogate_file, surrogate_key)
      bucket_name = Utils.split_id(object_id)
      begin
        @client.put_object(
          bucket: with_prefix(bucket_name),
          body: File.open(Pathname.new(surrogate_file)),
          key: surrogate_key)
      rescue Exception  => e
        Rails.logger.error "Problem saving Surrogate file #{surrogate_key}: #{e.to_s}"
      end
    end

    # Save arbitrary file
    def store_file(file, file_key, bucket_name)
      begin
        @client.put_object(
          bucket: with_prefix(bucket_name),
          body: File.open(Pathname.new(file)),
          key: file_key)
        @client.put_object_acl(
          acl: "public-read",
          bucket: with_prefix(bucket_name),
          key: file_key)

        return true
      rescue Exception => e
        Rails.logger.error "Problem saving file #{file_key}: #{e.to_s}"
        
        return false
      end
    end

    # Get an authenticated short-duration url for a file
    def get_link_for_surrogate(bucket, file, expire=nil)
      expire = Settings.S3.expiry unless (!expire.blank? && numeric?(expire))
      begin
        url = create_url(bucket, file, expire)
      rescue Exception => e
        Rails.logger.error "Problem getting link for file #{file}: #{e.to_s}"
      end
      return url
    end

    # Get link for arbitrary file
    def get_link_for_file(bucket, file)
      begin
        url = create_url(bucket, file, nil, false)
      rescue Exception => e
        Rails.logger.error "Problem getting link for file #{file}: #{e.to_s}"
      end
      return url
    end

    def list_files(bucket)
      files = []
      begin
        response = @client.list_objects(bucket: with_prefix(bucket))
        files = response.contents.map(&:key)
      rescue
        Rails.logger.debug "Problem listing files in bucket #{bucket}"
      end

      files
    end

  private

    def bucket_prefix
      if Settings.S3.bucket_prefix
        "#{Settings.S3.bucket_prefix}.#{Rails.environment}"
      else
        nil
      end
    end 

    def with_prefix bucket
      bucket_prefix ? "#{bucket_prefix}.#{bucket}" : bucket
    end

    def create_url(bucket, object, expire=nil, authenticated=true)
      if authenticated
        signed_url(with_prefix(bucket), object, expiration_timestamp(expire))
      else
        s3 = Aws::S3::Resource.new(client: @client) 
        
        s3.bucket(with_prefix(bucket)).objects.each do |o|        
          if o.key.eql?(object)
            return o.object.public_url
          end
        end
      end
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

    def signed_url(bucket, path, expire_date=nil)
      can_string = "GET\n\n\n#{expire_date}\n/#{bucket}/#{path}"

      signature = URI.encode_www_form_component(Base64.encode64(hmac(Settings.S3.secret_access_key, can_string)).strip)
   
      querystring = "AWSAccessKeyId=#{Settings.S3.access_key_id}&Expires=#{expire_date}&Signature=#{signature}"
      
      endpoint = URI.parse(Settings.S3.server)
      uri_class = endpoint.scheme.eql?("https") ? URI::HTTPS : URI::HTTP
      uri_class.build(:host => endpoint.host,
                      :port => endpoint.port,
                      :path => "/#{bucket}/#{path}",
                      :query => querystring).to_s
    end

    # Computes an HMAC digest of the passed string.
    # @param [String] key
    # @param [String] value
    # @param [String] digest ('sha256')
    # @return [String]
    def hmac key, value, digest = 'sha1'
      OpenSSL::HMAC.digest(OpenSSL::Digest.new(digest), key, value)
    end 

  end
end
