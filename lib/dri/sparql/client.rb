module DRI
  module Sparql
    class Client

      def initialize(endpoint)
        @sparql = SPARQL::Client.new(endpoint)
      end

      def query(select)
        @sparql.query(select)
      rescue Exception => e
        Rails.logger.error "Unable to query sparql endpoint: #{e.message}"
      end
    end
  end
end
