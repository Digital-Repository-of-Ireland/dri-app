require 'rails_helper'
require 'swagger_helper'

describe Resolvers::CollectionsSearch, type: :graphql do
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
      # env issue, this should be empty
      # DRI::QualifiedDublinCore.where(is_collection_sim: 'true', status: 'published').map(&:id).reject {|v| @collections.map(&:id).include?(v) }
      # published subcollections were not getting deleted since they were not added to @collections
      
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
    # graphql_fields = Types::CollectionType.fields.keys.sort.reject do |field|
    #   # id is a special case. It can't be changed once it's set
    #   # publishedAt is a generated singular value
    #   # governed_item_ids must refer to real active fedora objects, Exception: ActiveFedora::ObjectNotFoundError
    #   # relation issue with relation _tesim and _sim never matching anything using .where
    #   %w[
    #       id publishedAt createDate modifiedDate rootCollection 
    #       depositingInstitute governed_item_ids relation
    #     ].include?(field)
    # end.map(&:underscore) # convert camel to snake case

    ###############################################
    graphql_fields = %w[
      contributor coverage creator date description geographical_coverage 
      institute language licence published_date qdc_id 
      rights subject temporal_coverage title 
    ]

    # Types::CollectionType.fields.keys.sort.each do |field|
    #   xit "should test #{field}" unless graphql_fields.include?(field.underscore)
    #   # ["createDate", "depositingInstitute", "governedItemIds", "id", "modifiedDate", "publishedAt", "relation", "rootCollection"]
    # end

    graphql_fields.each do |field_name|
      describe "#{field_name}_contains" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name
          it 'should return fuzzy matches' do            
            # should match filter_test and other_filter_test
            result = get_graphql_results(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(2)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name 
          it 'should return an empty object when there are no matches found' do
            result = get_graphql_results(filter_func: "#{field_name}_contains")
            expect(result.length).to eq(0)
          end
        end
      end
      describe "#{field_name}_is" do
        context 'results' do
          include_context 'filter_test results exist', field: field_name
          it 'should return exact matches' do
            # should only match filter_test, not other_filter_test
            result = get_graphql_results(filter_func: "#{field_name}_is")
            expect(result.length).to eq(1)
          end
        end
        context 'no results' do
          include_context 'filter_test results do not exist', field: field_name 
          it 'should not match anything when there are no matches found' do
            result = get_graphql_results(filter_func: "#{field_name}_is")
            expect(result.length).to eq(0)
          end
        end
      end
    end
  end
end
