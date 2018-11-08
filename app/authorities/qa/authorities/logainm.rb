require 'httparty'
# require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # limit is 100, timeout after 5 seconds
      # regex query so will be slow
      # but allows for non-exact matches e.g. Henry_Street_(Dublin)

      # SELECT distinct ?s ?p ?o
      # WHERE {
      #   ?s ?p ?o .
      #   FILTER regex(?o, "locha", "i")
      # }
      # LIMIT 100
      url = "http://data.logainm.ie/sparql?default-graph-uri=&query=SELECT+distinct+%3Fs+%3Fp+%3Fo%0D%0AWHERE+%7B%0D%0A++%3Fs+%3Fp+%3Fo+.%0D%0A++FILTER+regex%28%3Fo%2C+%22#{_q}%22%2C+%22i%22%29%0D%0A%7D%0D%0ALIMIT+100&format=application%2Fsparql-results%2Bjson&timeout=5000&debug=on"
      response = HTTParty.get(url)
      json_response = JSON.parse(response.body, symbolize_names: true)
      json_response[:results][:bindings].map do |h| 
        {
          id: h[:s][:value],
          label: h[:o][:value],
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

    #   url = "#{sparql_endpoint}?#{query}&format=application%2Fsparql-results%2Bjson&timeout=5000"
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

# # find everything that is not a logainm/place
# SELECT distinct ?s ?p ?o
# WHERE {
#   ?s ?p ?o .
#   FILTER regex(?s, "^(?!http://data.logainm.ie/place).*$", "i")
# }


# find every logainm place with a similar name to locha
# SELECT distinct ?s ?o
# WHERE {
#   ?s ?p ?o .
#   FILTER regex(?s, "^http://data.logainm.ie/place/(.*)$", "i")
#   FILTER regex(?o, "locha", "i")
# }
