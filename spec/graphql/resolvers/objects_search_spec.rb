require 'rails_helper'
require 'swagger_helper'
# TODO: speed up graphql specs
# TODO: move to api specs, use http requests (OR if http requests are much slower)
# move generic contexts (e.g rswag_user_with_collections) into common API shared context


describe Resolvers::ObjectsSearch, type: :request do
  include_context 'rswag_user_with_collections', 
                  status: 'published', num_collections: 4, subcollection: false

  describe 'first' do
    # call([[:req, :object], [:req, :args], [:req, :context]])
    let(:result) { subject.class.call(nil, {first: 2}, nil) }

    it 'limits the number of results' do
      # should return first two objects
      expect(result.map(&:id).size).to eq(2)
    end
    it 'gets the first n results' do      
      expect(result.map(&:id)).to eq(@objects.slice(0, 2).map(&:id))
    end
  end
  describe 'skip' do
    let(:result) { subject.class.call(nil, {first: 2, skip: 1}, nil) }

    it 'adds an offset to the results' do
      # get second and third object
      expect(result.map(&:id)).to eq(@objects.slice(1, 2).map(&:id))
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

    ###############################################
    graphql_fields = %w[
      contributor coverage creator date description geographical_coverage 
      institute language licence published_date qdc_id 
      rights subject temporal_coverage title type format
    ]

    graphql_fields.each do |field_name|
      describe "#{field_name}_contains" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name, type: 'Object'
          it 'should return fuzzy matches' do            
            # should match filter_test and other_filter_test
            result = get_results.call(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(2)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name, type: 'Object'
          it 'should return an empty object when there are no matches found' do
            result = get_results.call(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(0)
          end
        end
      end
      describe "#{field_name}_is" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name, type: 'Object'
          it 'should return exact matches' do
            # should only match filter_test, not other_filter_test
            result = get_results.call(filter_func: "#{field_name}_is")
            expect(result.length).to eq(1)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name, type: 'Object'
          it 'should not match anything when there are no matches found' do
            result = get_results.call(filter_func: "#{field_name}_is")
            expect(result.length).to eq(0)
          end
        end
      end
    end
  end
end
