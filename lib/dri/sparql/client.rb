module DRI
 module Sparql
   class Client

     def initialize(endpoint)
         @sparql = SPARQL::Client.new(endpoint)
     end

     def query select
       results = nil
       begin
         results = @sparql.query(select)
       rescue Exception => e
         Rails.logger.error "Unable to query sparql endpoint: #{e.message}"
       end
       results
     end

    end
  end
end
