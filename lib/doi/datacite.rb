require 'rest_client'
require 'uri'

module DOI
  class Datacite

    def initialize(doi)
      @doi = doi
      @url = DoiConfig.base_url
      @service = RestClient::Resource.new(
        DoiConfig.url,
        user: DoiConfig.username,
        password: DoiConfig.password,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      )
    end

    def mint
      path = @doi.doi.split('/')[1].split('.')[1]
      url = URI.join(@url, 'objects/', "#{@doi.object_id}/", 'doi/', "#{path}")

      payload = "doi=#{@doi.doi}\nurl=#{url}"
      response = @service["doi/#{@doi.doi}"].put(payload, content_type: 'text/plain;charset=UTF-8')
      Rails.logger.info("Minted DOI (#{response.code} #{response.body})")

      response.code
    end

    def metadata
      xml = @doi.to_xml
      response = @service["metadata/#{@doi.doi}"].put(xml, content_type: 'application/xml;charset=UTF-8')

      Rails.logger.info("Created DOI metadata (#{response.code} #{response})")

      response.code
    end

    def doi_exists?
      response = @service["doi/#{@doi.doi}"].head
      return true if response.code == 200
      false
    end
  end
end
