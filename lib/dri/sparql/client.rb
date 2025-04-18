# frozen_string_literal: true
module DRI
  module Sparql
    class Client
      def initialize(endpoint)
        @sparql = SPARQL::Client.new(endpoint)
      end

      def query(select)
        @sparql.query(select)
      rescue StandardError => e
        Rails.logger.error "Unable to query sparql endpoint: #{e.message}"
        nil # rails logger call returns True
      end
    end
  end
end
