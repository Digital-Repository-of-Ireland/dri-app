require 'httparty'

module Qa::Authorities
  class Unesco < Qa::Authorities::Base
    def search(_q)
      # http://vocabularies.unesco.org/sparql-form/
      # make a search on all concept labels
      #
      # only matches english labels
      #
      # PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      # PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      # PREFIX isothes: <http://purl.org/iso25964/skos-thes#>
      # PREFIX text: <http://jena.apache.org/text#>
      # SELECT DISTINCT ?concept ?prefLabel
      # WHERE {
      #   {
      #     {
      #       ?concept text:query (skos:prefLabel 'education*' 100000)
      #     }       UNION         {
      #       ?concept text:query (skos:altLabel 'education*' 100000)
      #     }        UNION         {
      #       ?concept text:query (skos:hiddenLabel 'education*' 100000)
      #     }
      #   }          {
      #     ?concept rdf:type <http://www.w3.org/2004/02/skos/core#Concept> .
      #     ?concept skos:prefLabel ?prefLabel .
      #     FILTER(langMatches(lang(?prefLabel), 'en'))
      #   }
      # }
      url = "http://vocabularies.unesco.org/sparql?default-graph-uri=&query=PREFIX+rdf%3A+%3Chttp%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23%3E+%0D%0APREFIX+skos%3A+%3Chttp%3A%2F%2Fwww.w3.org%2F2004%2F02%2Fskos%2Fcore%23%3E+%0D%0APREFIX+isothes%3A+%3Chttp%3A%2F%2Fpurl.org%2Fiso25964%2Fskos-thes%23%3E+%0D%0APREFIX+text%3A+%3Chttp%3A%2F%2Fjena.apache.org%2Ftext%23%3E+%0D%0ASELECT+DISTINCT+%3Fconcept+%3FprefLabel+%0D%0AWHERE+%7B%0D%0A+%7B%0D%0A+%7B%0D%0A+%3Fconcept+text%3Aquery+%28skos%3AprefLabel+%27#{_q}*%27+100000%29+%0D%0A+%7D+UNION+%7B%0D%0A+%3Fconcept+text%3Aquery+%28skos%3AaltLabel+%27#{_q}*%27+100000%29+%0D%0A+%7D+UNION+%7B%0D%0A+%3Fconcept+text%3Aquery+%28skos%3AhiddenLabel+%27#{_q}*%27+100000%29+%0D%0A+%7D+%0D%0A+%7D+%7B%0D%0A+%3Fconcept+rdf%3Atype+%3Chttp%3A%2F%2Fwww.w3.org%2F2004%2F02%2Fskos%2Fcore%23Concept%3E+.%0D%0A+%3Fconcept+skos%3AprefLabel+%3FprefLabel+.%0D%0A+FILTER%28langMatches%28lang%28%3FprefLabel%29%2C+%27en%27%29%29+%0D%0A+%7D+%0D%0A%7D&format=application%2Fsparql-results%2Bjson&stylesheet=%2Fsparql-form%2Fxsl%2Fxml-to-html.xsl"
      response = HTTParty.get(url)
      json_response = JSON.parse(response.body, symbolize_names: true)
      json_response[:results][:bindings].map do |res_hash|
        {
          id:    res_hash[:concept][:value],
          label: res_hash[:prefLabel][:value],
        }
      end
    end
  end
end
