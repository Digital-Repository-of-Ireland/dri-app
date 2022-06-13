# frozen_string_literal: true
require 'aws-sdk-s3'

module Storage
  class S3UrlUtils
    def initialize(client)
      @client = client
    end

    def create_url(bucket, object, expire = nil, authenticated = true)
      return signed_url(bucket, object, expiration_timestamp(expire)) if authenticated

      s3 = Aws::S3::Resource.new(client: @client)

      s3.bucket(bucket).objects.each do |o|
        return o.object.public_url if o.key.eql?(object)
      end

      nil
    end

    private

    def expiration_timestamp(input)
      input = input.to_int if input.respond_to?(:to_int)
      case input
      when Time then input.to_i
      when DateTime then Time.parse(input.to_s).to_i
      when Integer then (Time.now + input).to_i
      when String then Time.parse(input).to_i
      else (Time.now + 60 * 60).to_i
      end
    end

    def signed_url(bucket, path, expire_date = nil)
      can_string = "GET\n\n\n#{expire_date}\n/#{bucket}/#{path}"

      signature = URI.encode_www_form_component(Base64.encode64(hmac(Settings.S3.secret_access_key, can_string)).strip)

      querystring = "AWSAccessKeyId=#{Settings.S3.access_key_id}&Expires=#{expire_date}&Signature=#{signature}"

      endpoint = URI.parse(Settings.S3.server)
      uri_class = endpoint.scheme == "https" ? URI::HTTPS : URI::HTTP
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
