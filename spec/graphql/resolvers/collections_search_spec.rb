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
      ->(filter_func: '', filter_arg: 'filter_test') do
        filter_args = { filter: { "#{filter_func}": filter_arg } }
        subject.class.call(nil, filter_args, nil)
      end
    end

    graphql_fields = Types::CollectionType.fields.keys.sort.reject do |field|
      # id is a special case. It can't be changed once it's set
      # publishedAt is a generated singular value
      # TODO: determine if field is multival here
      %w[id publishedAt createDate modifiedDate rootCollection depositingInstitute].include?(field)
    end.map(&:underscore) # convert camel to snake case

    # graphql_fields = ['coverage']

    graphql_fields.each do |field_name|
      describe "#{field_name}_contains" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name
          it 'should return fuzzy matches' do            
            # should match filter_test and filter
            result = get_results.call(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(2)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name 
          it 'should return an empty object when there are no matches found' do
            result = get_results.call(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(0)
          end
        end
      end
      describe "#{field_name}_is" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name
          it 'should return exact matches' do
            result = get_results.call(filter_func: "#{field_name}_is")
            expect(result.length).to eq(1)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name 
          it 'should not match anything when there are no matches found' do
            result = get_results.call(filter_func: "#{field_name}_is")
            expect(result.length).to eq(0)
          end
        end
      end
      # context 'filter_test results do no exist' do
      #   ["#{field_name}_is", "#{field_name}_contains"].each do |filter_func|
      #     it "#{filter_func}" do
      #       filter_args = { filter: { "#{filter_func}": 'filter_test' } }
      #       result = subject.class.call(nil, filter_args, nil)
      #       expect(result.size).to eq(0)
      #     end
      #   end
      # end
    end
  end
end
