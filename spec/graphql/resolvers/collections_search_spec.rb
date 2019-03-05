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
    # call([[:req, :object], [:req, :args], [:req, :context]])
    let(:result) { subject.class.call(nil, {first: 2}, nil) }

    it 'limits the number of results' do
      # should return first two objects
      expect(result.map(&:id).size).to eq(2)
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
  describe 'filter' do
    # TODO move to helper module once search_api is merged
    let(:get_results) do
      ->(filter_func: 'description_is', filter_arg: 'filter_test') do
        filter_args = { filter: { "#{filter_func}": filter_arg } }
        subject.class.call(nil, filter_args, nil)
      end
    end

    context 'filter_test results exist' do
      before(:each) do
        published_collections = @collections.select do |col|
          col.status == 'published'
        end

        published_collections.first.description = ['filter_test']
        published_collections.first.save!

        published_collections.last.description = ['other_filter_test']
        published_collections.last.save!
      end
      describe 'contains' do
        it 'should return fuzzy matches' do
          # should match filter_test and filter
          result = get_results.call(filter_func: 'description_contains')
          expect(result.length).to eq(2)
        end
      end
      describe 'is' do
        it 'should return exact matches' do
          result = get_results.call
          expect(result.length).to eq(1)
        end
      end
    end
    context 'filter_test results do no exist' do
      %w[description_is description_contains].each do |filter_func|
        it "#{filter_func} not match anything" do
          filter_args = { filter: { "#{filter_func}": 'filter_test' } }
          result = subject.class.call(nil, filter_args, nil)
          expect(result.size).to eq(0)
        end
      end
    end
  end
end
