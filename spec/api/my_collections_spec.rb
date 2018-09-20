require 'swagger_helper'

describe "My Collections API" do
  path "/my_collections" do
    get "retrieves objects, collections, or subcollections for the current user" do
      tags 'Private (Sign in required)'
      # TODO accept ttl and xml on default route too
      # not just specific objects
      # TODO add json format for /my_collections/:id/duplicates
      produces 'application/json'

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9, required: false
      parameter name: :page, description: 'Page number', 
        in: :query, type: :number, default: 1, required: false
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, required: false, default: 'objects', type: :string,
        enum: ['objects', 'collections']
      parameter name: :show_subs, description: 'Show subcollections',
        in: :query, type: :boolean, default: false
      parameter name: :search_field, description: 'Solr field to search for',
        in: :query, type: :string, default: 'all_fields'
      parameter name: :sort, description: 'Solr fields to sort by',
        in: :query, type: :string, default: nil
      parameter name: :q, description: 'Search Query',
        in: :query, type: :string, default: nil
      # # issue with facets beign empty string
      # parameter name: :f, description: 'Search facet (solr fields to filter results)',
        # in: :query, type: :string, default: nil

      # undefined method `per_page' when not set
      let(:per_page)     { 9 }
      let(:page)         { 1 }
      # although when you visit /my_collections in a web browser mode=collections
      # if you call /my_collections.json you get objects, not only collections
      let(:mode)         { 'objects' }
      let(:show_subs)    { false }
      let(:search_field) { 'all_fields' }
      let(:sort)         { nil }
      let(:q)            { nil }
      # let(:f)            { nil }
      
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        include_context 'rswag_include_json_spec_output'

        it "should require a sign in" do 
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      context "Signed in user with collections" do
        include_context 'signed_in_user_with_collections'

        response "200", "All objects found" do
          context 'All objects found' do
            include_context 'rswag_include_json_spec_output', 
              example_name='/my_collections.json'
            run_test! do
              expect(status).to eq(200) 
            end
          end
          context 'All collections found' do
            include_context 'rswag_include_json_spec_output', 
              example_name='/my_collections.json?mode=collections'

            before do |example|
              submit_request(example.metadata)
            end
            let(:mode) { 'collections' }
            it 'returns 200' do
              expect(status).to eq(200) 
            end
          end 
          context 'Show subcollections' do
            include_context 'rswag_include_json_spec_output', 
              example_name='/my_collections.json?mode=collections&show_subs=true'
            include_context 'subcollection'
            let(:mode) { 'collections' }
            let(:show_subs) { true }
            run_test! do
              expect(status).to eq(200) 
            end
          end
          context 'Limit results' do
            include_context 'rswag_include_json_spec_output', 
              example_name='/my_collections.json?per_page=1'
            let(:per_page) { 1 }
            run_test! do
              expect(status).to eq(200) 
            end
          end
        end
      end
    end
  end

  path "/my_collections/{id}" do
    include_context 'signed_in_user_with_collections'

    get "retrieves a specific object, collection or subcollection" do
      tags 'Private (Sign in required)'
      produces 'application/json', 'application/xml', 'application/ttl'
      parameter name: :id, description: 'Object ID',
        in: :path, :type => :string

      # TODO: make api response consistent
      # always return sign in error when not signed in on route that requires it
      # can't include rspec output since it's an empty sting (not json)
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        let(:id) { @collections.first.id }

        it 'returns a 401 when the user is not signed in' do
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      response "404", "Object not found" do
        # doesn't matter whether you're signed in
        # 404 takes precendence over 401
        include_context 'sign_out_before_request'
        include_context 'rswag_include_json_spec_output'

        let(:id) { "collection_that_does_not_exist" }

        it 'returns a 404 when the user is not signed in' do
          expect(status).to eq(404) 
        end
      end

      response "200", "Object found" do
        include_context 'rswag_include_json_spec_output'
        let(:id) { @collections.first.id }
        run_test! do
          expect(status).to eq(200) 
        end
      end
    end
  end
end

