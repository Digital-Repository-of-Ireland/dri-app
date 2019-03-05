module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    include Helpers::SolrHelper
  end
end
