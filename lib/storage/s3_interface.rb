# frozen_string_literal: true
require 'aws-sdk-s3'

module Storage
  class S3Interface
    def initialize(options = {})
      endpoint = Settings.S3.server
      credentials = Aws::Credentials.new(Settings.S3.access_key_id, Settings.S3.secret_access_key)

      params = options.merge(
                 {
                   region: 'us-east-1',
                   endpoint: endpoint,
                   credentials: credentials,
                   ssl_verify_peer: false,
                   force_path_style: true,
                   signature_version: 's3'
                 }
               )
      @client = Aws::S3::Client.new(params)
      @url_utils = ::Storage::S3UrlUtils.new(@client)
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
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Could not create Storage Bucket #{bucket}: #{e}"
      false
    end

    def create_upload_bucket(bucket)
      return false unless @client.create_bucket(bucket: with_prefix(bucket))

      @client.put_bucket_cors({
        bucket: with_prefix(bucket), 
        cors_configuration: {
          cors_rules: [
            {
              allowed_headers: [
                "content-type", 
              ], 
              allowed_methods: [
                "PUT", 
                "POST",
                "GET"
              ], 
              allowed_origins: [
                "*", 
              ], 
              expose_headers: [
                "x-amz-server-side-encryption",
                "ETag",
                "Location",
              ]
            }, 
          ], 
        }, 
      })

      true
    end

    # Delete bucket
    def delete_bucket(bucket_name)
      return false unless bucket_exists?(bucket_name)

      objects = list_files(bucket_name)
      objects.each { |obj| @client.delete_object(bucket: with_prefix(bucket_name), key: obj) }

      @client.delete_bucket(bucket: with_prefix(bucket_name))
      true
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Could not delete Storage Bucket #{bucket_name}: #{e}"
      false
    end

    def delete_surrogates(bucket, key)
      objects = list_files(bucket, key)
      objects.each { |obj| @client.delete_object(bucket: with_prefix(bucket), key: obj) }
      true
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Could not delete surrogate for #{key}: #{e}"
      false
    end

    # Get a hash of all surrogates for an object
    # object - SolrDocument or object ID
    # file = SolrDocument or GenericFile ID
    def get_surrogates(object, file, expire = nil)
      expire = Settings.S3.expiry unless !expire.nil? && numeric?(expire)
      bucket = object.respond_to?(:alternate_id) ? object.alternate_id : object
      generic_file_id = file.respond_to?(:alternate_id) ? file.alternate_id : file

      surrogate_file_names = list_files(bucket, generic_file_id)
      surrogates_hash = {}

      surrogate_file_names.each do |filename|
        url = @url_utils.create_url(with_prefix(bucket), filename, expire)
        surrogates_hash[key_from_filename(generic_file_id, filename)] = url
      rescue Aws::S3::Errors::ServiceError => e
        Rails.logger.debug "Problem getting url for file #{generic_file_id} : #{e}"
      end

      surrogates_hash
    end

    def list_surrogates(object)
      @surrogate_list ||= list_files(object)
    end

    # Get url for a specific surrogate
    def surrogate_exists?(bucket, key)
      return nil unless bucket_exists?(bucket)

      resource = Aws::S3::Resource.new(client: @client)
      return nil if resource.bucket(with_prefix(bucket)).objects(prefix: key).collect(&:key).blank?

      true
    end

    # Get information about surrogates for a generic_file
    def surrogate_info(bucket, key)
      surrogates_hash = {}
      begin
        response = @client.list_objects(bucket: with_prefix(bucket), prefix: key)

        if response.successful?
          response.contents.each do |fileobj|
            surrogates_hash[fileobj.key] = @client.head_object(bucket: with_prefix(bucket), key: fileobj.key) if filename_match?(fileobj.key, key)
          end
        else
          Rails.logger.debug "Problem getting surrogate info for file #{key}"
        end
      rescue Aws::S3::Errors::ServiceError => e
        Rails.logger.debug "Problem getting surrogate info for file #{key} : #{e}"
      end

      surrogates_hash
    end

    # Get url for a specific surrogate
    def surrogate_url(bucket, key, expire = nil)
      expire = Settings.S3.expiry unless expire.present? && numeric?(expire)

      surrogate = list_files(bucket, key)

      if surrogate.present?
        begin
          url = @url_utils.create_url(with_prefix(bucket), surrogate.first, expire)
        rescue Aws::S3::Errors::ServiceError => e
          Rails.logger.debug "Problem getting url for file #{surrogate.first}: #{e}"
        end
      end

      url
    end

    def file_url(bucket, key)
      @url_utils.create_url(with_prefix(bucket), key, nil, false)
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Problem getting url for file #{bucket} #{key}: #{e}"
      nil
    end

    def put_url(bucket, key, content_type, prefix = false)
       bucket = with_prefix(bucket) if prefix
       s3 = Aws::S3::Resource.new(client: @client)
       bucket_obj = s3.bucket(bucket)
       obj = bucket_obj.object(key)
      
       obj.presigned_url(:put)
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Problem getting url for file #{bucket} #{key}: #{e}"
      nil
    end

    # Save Surrogate File
    def store_surrogate(bucket, surrogate_file, surrogate_key, mimetype = nil)
      @client.put_object(
        bucket: with_prefix(bucket),
        body: File.open(Pathname.new(surrogate_file)),
        key: surrogate_key,
        content_type: mimetype
      )

      true
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Problem saving Surrogate file #{surrogate_key}: #{e}"
      false
    end

    # Save arbitrary file
    def store_file(bucket, file, file_key, mimetype = nil)
      prefixed_bucket = with_prefix(bucket)
      @client.put_object(
        bucket: prefixed_bucket,
        body: File.open(Pathname.new(file)),
        key: file_key,
        content_type: mimetype
      )
      @client.put_object_acl(acl: 'public-read', bucket: prefixed_bucket, key: file_key)
      true
    rescue Aws::S3::Errors::ServiceError => e
      Rails.logger.error "Problem saving file #{file_key}: #{e}"
      false
    end

    def download_file(bucket, file, target, prefix = false)
      bucket = with_prefix(bucket) if prefix
      @client.get_object(
        response_target: target.path,
        bucket: bucket,
        key: file
      )
    end

    private

    def bucket_prefix
      Settings.S3.bucket_prefix ? "#{Settings.S3.bucket_prefix}.#{Rails.env}" : nil
    end

    def key_from_filename(generic_file_id, filename)
      File.basename(filename, '.*').split("#{generic_file_id}_")[1]
    end

    def filename_match?(filename, generic_file_id)
      /#{generic_file_id}_([-a-zA-z0-9]*)\..*/ =~ filename
    end

    def list_files(bucket, file_prefix = nil)
      options = { bucket: with_prefix(bucket) }
      options[:prefix] = file_prefix if file_prefix

      files = []
      response = {}
      loop do
        options[:continuation_token] = response[:next_continuation_token] if response[:next_continuation_token].present?
        response = @client.list_objects_v2(options)
        files.concat(response.contents.map(&:key))
        break if response[:is_truncated] == false
      end

      files
    rescue
      Rails.logger.debug "Problem listing files in bucket #{bucket}"
      []
    end

    def numeric?(number)
      Integer(number)
    rescue
      false
    end

    def with_prefix(bucket)
      bucket_prefix ? "#{bucket_prefix}.#{bucket}" : bucket
    end
  end
end
