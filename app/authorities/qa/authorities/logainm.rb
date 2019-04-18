require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # filter by CONTAINS LCASE instead of REGEX to speed up query
      # use SAMPLE instead of GROUP BY to speed up query, since link itself doesn't matter
      # binding intermediate var seems to slow query down, so call LCASE each time
      # ORDER BY exact matches first, then place names from a-z

      sparql_endpoint = 'http://data.logainm.ie/sparql'
      client = SPARQL::Client.new(sparql_endpoint)
      query_text = "
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>

        SELECT ?place_name (SAMPLE(?tmp_links) AS ?link)
        WHERE {
          ?tmp_links foaf:name ?place_name .
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
