module Qa::Authorities
  class Homosaurus < Qa::Authorities::Base
    def search(q)
      url = "https://homosaurus.org/search/v2.jsonld?q=#{q}*"
      response = HTTParty.get(url, verify: false)
      json_response = JSON.parse(response.body)
      return {} unless json_response.key?('@graph')

      json_response['@graph'].map do |res_hash|
        {
          label: res_hash['skos:prefLabel']['@value'],
          id: res_hash['@id']
        }
      end
    end
  end
end
