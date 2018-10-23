require 'httparty'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # limit is 100, timeout after 5 seconds
      # regex query so will be slow

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
          label: h[:o][:value],
          id: h[:s][:value],
        }
      end
    end
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
