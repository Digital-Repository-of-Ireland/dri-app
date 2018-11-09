require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # filter by CONTAINS LCASE instead of REGEX to speed up query
      # use SAMPLE instead of GROUP BY to speed up query, 
      # since link itself doesn't matter
      # binding intermediate var seems to slow query down, so call LCASE each time
      # ORDER BY exact matches first, then place names from a-z

      # could also use rails to_query helper to generate url
      # and then use HTTParty.get as http client e.g.
      # HTTParty.get("#{sparql_endpoint}?#{query_text.to_query('query')}&format=application%2Fsparql-results%2Bjson")

      sparql_endpoint = 'http://data.logainm.ie/sparql'
      client = SPARQL::Client.new(sparql_endpoint)
      query_text = "
        SELECT ?place_name (SAMPLE(?link) AS ?link)
        WHERE {
          ?link foaf:name ?place_name .
          FILTER(CONTAINS(LCASE(?place_name), '#{_q}'))
          BIND(STRSTARTS(LCASE(?place_name), '#{_q}') as ?match)
        }
        ORDER BY DESC(?match) ASC(?place_name)
        LIMIT 50
      "
      query = client.query(query_text)
      query.to_a.map do |h| 
        {
          label: h[:place_name].to_s, 
          id: h[:link].to_s
        }
      end
    end
  end
end
