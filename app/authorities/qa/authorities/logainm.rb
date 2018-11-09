require 'httparty'
# require 'sparql/client'

module Qa::Authorities
  class Logainm < Qa::Authorities::Base
    def search(_q)
      # # limit is 100, timeout after 5 seconds
      # # regex query so will be slow
      # # but allows for non-exact matches
      # # only get names of places, so misses isReferencedBy etc
      # # get min ranked link and group by so places are unique
      # SELECT MIN(?link) ?place_name
      # WHERE {
      #   ?link ?o ?place_name .
      #   ?link foaf:name ?place_name
      #   FILTER(regex(?place_name, "dublin", "i"))
      # } GROUP BY ?place_name

      url = "http://data.logainm.ie/sparql?default-graph-uri=&query=++++SELECT+MIN%28%3Flink%29+%3Fplace_name%0D%0A++++WHERE+%7B%0D%0A++++++%3Flink+%3Fo+%3Fplace_name+.%0D%0A++++++%3Flink+foaf%3Aname+%3Fplace_name%0D%0A++++++FILTER%28regex%28%3Fplace_name%2C+%22#{_q}%22%2C+%22i%22%29%29%0D%0A++++%7D+GROUP+BY+%3Fplace_name&format=application%2Fsparql-results%2Bjson"
      response = HTTParty.get(url)
      json_response = JSON.parse(response.body, symbolize_names: true)
      json_response[:results][:bindings].map do |h| 
        {
          # id: h[:s][:value],
          # label: h[:o][:value],
          id: h[:place][:value],
          label: h[:name][:value],
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
# SELECT distinct ?s ?p ?o
# WHERE {
#   ?s ?p ?o .
#   FILTER regex(?s, "^http://data.logainm.ie/place/(.*)$", "i")
#   FILTER regex(?o, "locha", "i")
# }

# # find subject, predicate, object 
# # where name of subject matches locha
# PREFIX foaf: <http://xmlns.com/foaf/0.1/>
# SELECT ?s ?p ?o
# WHERE {
#   ?s ?p ?o .
#   FILTER(?p = foaf:name)
#   FILTER(regex(?o, "locha", "i"))
# }
# # produces data.logainm/place links, which are all dead :(

# PREFIX dc: <http://purl.org/dc/terms/>
# SELECT ?s ?p ?o
# WHERE {
#   ?s ?p ?o .
#   FILTER(?p = dc:isReferencedBy)
#   FILTER(regex(?o, "locha", "i"))
# }

# PREFIX foaf: <http://xmlns.com/foaf/0.1/>
# SELECT ?place ?name
# WHERE {
#   # find all places with name "An Clochar"@ga
#   ?place foaf:name "An Clochar"@ga .
#   # save foaf:name as new variable named ?name
#   ?place foaf:name ?name .
# }

