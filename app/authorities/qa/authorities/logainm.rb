require 'httparty'
# require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # # use contains instead of regex match to speed up query
      # # use sample instead of group by since link itself doesn't matter 
      # # intermediate var seems to slow query down, so call LCASE each time
      # # order by exact matches first, then place names from a-z
      # SELECT ?place_name (SAMPLE(?link) AS ?link)
      # WHERE {
      #   ?link foaf:name ?place_name .
      #   FILTER (CONTAINS(LCASE(?place_name), 'college'))
      #   bind( STRSTARTS(LCASE(?place_name), 'college') as ?match )
      # }
      # ORDER BY DESC(?match) ASC(?place_name)
      # LIMIT 50

      url = "http://data.logainm.ie/sparql?default-graph-uri=&query=SELECT+%3Fplace_name+%28SAMPLE%28%3Flink%29+AS+%3Flink%29%0D%0A+WHERE+%7B%0D%0A+%3Flink+foaf%3Aname+%3Fplace_name+.%0D%0A+FILTER+%28CONTAINS%28LCASE%28%3Fplace_name%29%2C+%27#{_q}%27%29%29%0D%0A+bind%28+STRSTARTS%28LCASE%28%3Fplace_name%29%2C+%27#{_q}%27%29+as+%3Fmatch+%29%0D%0A+%7D%0D%0A+ORDER+BY+DESC%28%3Fmatch%29+ASC%28%3Fplace_name%29%0D%0A+LIMIT+50&format=application%2Fsparql-results%2Bjson"

      response = HTTParty.get(url)
      json_response = JSON.parse(response.body, symbolize_names: true)
      json_response[:results][:bindings].map do |h| 
        {
          # id: h[:s][:value],
          # label: h[:o][:value],
          id: h[:link][:value],
          label: h[:place_name][:value],
        }
      end
    end

    # # Issues with sparql client results as json
    # # Also sparql client doesn't work with unesco api
    # # SPARQL::Client::ServerError: Infinite redirect at http://vocabularies.unesco.org/sparql
    # # can use .to_query to build uri instead of using sparql client to make request
    # def search(_q)
    #   sparql_endpoint = 'http://data.logainm.ie/sparql'
    #   query = SPARQL::Client.new(sparql_endpoint)
    #       .select(distinct: true)
    #       .where([:s, :p, :o])
    #       .filter("regex(?o, '#{_q}', 'i')")
    #       .limit(10)
    #       .to_query('query')

    #   url = "{sparql_endpoint}?#{query}&format=application%2Fsparql-results%2Bjson"
    #   response = HTTParty.get(url)
    #   json_response = JSON.parse(response.body, symbolize_names: true)
    #   json_response[:results][:bindings].map do |h| 
    #     {
    #       id: h[:s][:value],
    #       label: h[:o][:value],
    #     }
    #   end
    # end
  end
end
