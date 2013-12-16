require 'rest_client'

module DOI
  class Datacite

    def initialize(object)
      @object = object
      @identifier = doi
      @url = DoiConfig.base_url
      @service = RestClient::Resource.new DoiConfig.url, DoiConfig.username, DoiConfig.password
    end

    def mint
      url = File.join(@url, 'catalog', @object.id)
      params = { "doi" => @identifier, "url" => url }
      response = @service['doi'].post(params, :content_type => 'text/plain;charset=UTF-8')
      logger.info("Minted DOI (#{response.code} #{response.body})")
    end

    def metadata
      xml = to_xml
      response = @service['metadata'].post(xml, :content_type => 'application/xml;charset=UTF-8')
      logger.info("Created DOI metadata (#{response.code} #{response.body})")
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.resource('xmlns'=>'http://datacite.org/schema/kernel-3', 
                   'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance', 
                   'xsi:schemaLocation'=>'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') {
        xml.identifier @identifier, :identifierType => 'DOI'
        xml.creators {
          @object.creator.each do |c|
            xml.creator {
              xml.creatorName c
            }
          end
        }
        xml.titles {
          @object.title.each do |t|
            xml.title t 
          end
        }
        xml.publisher @object.publisher.first unless @object.publisher.nil?
        xml.publicationYear publication_year
        xml.subjects {
          @object.subject.each do |s|
            xml.subject s
          end
        }
        xml.descriptions {
          @object.description.each do |d|
            xml.description d, :descriptionType => 'Abstract'
          end
        }   
      }
      end

      return builder.to_xml
    end

    def doi
      doi = @object.id.sub(':', '.')
      File.join(DoiConfig.prefix.to_s, doi)
    end

    def publication_year
      @object.published_date.first.nil? ? Time.now.year : Date.parse(@object.published_date.first).year
    end

  end
end
