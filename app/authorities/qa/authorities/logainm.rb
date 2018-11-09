require 'httparty'
# require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # # limit is 100, timeout after 5 seconds
      # # regex query so will be slow
      # # but allows for non-exact matches
      # # use sample instead of group by since link itself doesn't matter 
      # SELECT ?place_name (SAMPLE(?link) AS ?link)
      # WHERE {
      #   ?link foaf:name ?place_name .
      #   # FILTER (regex(?place_name, "henry", "i"))
      #   FILTER (CONTAINS(LCASE(?place_name), "henry"))
      # }
      # LIMIT 50

      url = "http://data.logainm.ie/sparql?default-graph-uri=&query=SELECT+%3Fplace_name+%28SAMPLE%28%3Flink%29+AS+%3Flink%29%0D%0A++++++WHERE+%7B%0D%0A++++++++%3Flink+foaf%3Aname+%3Fplace_name+.%0D%0A++++++++FILTER+%28CONTAINS%28LCASE%28%3Fplace_name%29%2C+%22#{_q}%22%29%29%0D%0A++++++%7D%0D%0A++++++LIMIT+50&format=application%2Fsparql-results%2Bjson"

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
