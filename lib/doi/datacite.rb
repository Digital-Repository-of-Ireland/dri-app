require 'rest_client'

module DOI
  class Datacite

    def initialize(doi)
      @doi = doi
      @url = DoiConfig.base_url
      @service = RestClient::Resource.new DoiConfig.url, DoiConfig.username, DoiConfig.password
    end

    def mint
      url = File.join(@url, 'catalog', @object.id)
      params = { "doi" => @doi.doi, "url" => url }
      response = @service['doi'].post(params, :content_type => 'text/plain;charset=UTF-8')
      Rails.logger.info("Minted DOI (#{response.code} #{response.body})")
    end

    def metadata
      xml = @doi.to_xml
      response = @service['metadata'].post(xml, :content_type => 'application/xml;charset=UTF-8')
      Rails.logger.info("Created DOI metadata (#{response.code} #{response.body})")
    end

  end
end
