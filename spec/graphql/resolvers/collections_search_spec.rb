require 'rails_helper'
require 'support/rswag_shared_contexts'
# TODO: move user / published collections shared contexts into common shared_context
# rename to API shared context / example once search_api branch is merged
# to avoid conflicts
# TODO: speed up graphql specs
# TODO: move to api specs, use http requests

describe Resolvers::CollectionsSearch, type: :request do
  include_context 'rswag_user_with_collections', 
                  status: 'published', num_collections: 4

  describe 'first' do
    # call(query_string, context, variables)
    let(:result) { subject.class.call(nil, {first: 2}, nil) }

    it 'limits the number of results' do
      # should return first two objects
      expect(result.map(&:id).count).to eq(2)
    end
    it 'gets the first n results' do
      expect(result.map(&:id)).to eq(@collections.slice(0, 2).map(&:id))
    end
  end
  describe 'skip' do
    let(:result) { subject.class.call(nil, {first: 2, skip: 1}, nil) }

    it 'adds an offset to the results' do
      # get second and third object
      expect(result.map(&:id)).to eq(@collections.slice(1, 2).map(&:id))
    end
  end
end
