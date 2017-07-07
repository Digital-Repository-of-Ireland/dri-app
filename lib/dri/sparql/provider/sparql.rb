require 'dri/sparql'

module DRI::Sparql
  module Provider
    class Sparql

      def endpoint=(endpoint)
        @endpoint = endpoint
      end

      def retrieve_data(triple)
        subject = triple[0] ? "<#{triple[0]}>" : '?s'
        predicate = triple[1] || '?p'
        object = triple[2] || '?o'

        select = "CONSTRUCT { ?s ?p ?o } WHERE 
                  { #{subject} #{predicate} #{object}
                   . ?s ?p ?o }"
        client = DRI::Sparql::Client.new @endpoint
        results = client.query select
        
        output = []
        return output if results.nil?

        results.each_triple do |s,p,o|
          output << [s, p, o]
        end
        output
      end
    end
  end
end