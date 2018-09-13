require 'swagger_helper'

describe "My Collections API" do
  path "/my_collections" do
    get "retrieves objects, collections, or subcollections for the current user" do
      tags 'Private (Sign in required)'
      # TODO accept ttl and xml on default route too
      # not just specific objects
      produces 'application/json'

      parameter name: :per_page, description: 'Number of results per page', 
        in: :query, type: :number, default: 9
      parameter name: :mode, description: 'Show Objects or Collections', 
        in: :query, type: :string, default: 'objects'

      # undefined method `per_page' when not set
      let(:per_page) { 9 }
      let(:mode)     { 'objects' }
      
      response "401", "Must be signed in to access this route" do
        include_context 'sign_out_before_request'
        include_context 'rswag_include_spec_output'

        it "should require a sign in" do 
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end

      context "Signed in user with collections" do
        include_context 'collections_with_objects'

        response "200", "All objects found" do
          include_context 'rswag_include_spec_output'
          run_test! do
            expect(status).to eq(200) 
          end
        end

        # TODO find a way to include multiple responses with the same code
        # https://github.com/domaindrivendev/rswag/issues/131
        # Larger issue with multiple responses in OpenAPI and swagger in general
        # https://github.com/OAI/OpenAPI-Specification/issues/270
        # https://github.com/swagger-api/swagger-ui/issues/3803
        response "200 ", "All collections found" do
          include_context 'rswag_include_spec_output'
          before do |example|
            submit_request(example.metadata)
          end
          let(:mode) { 'collections' }
          it 'returns 200' do
            expect(status).to eq(200) 
          end
        end

        # # hack using spaces to give separate responses
        # # must use it format, run_test! fails "200" != "200 "
        # response "200  ", "All objects found with a page limit of one" do
        #   include_context 'rswag_include_spec_output'
        #   let(:per_page) { 1 }
        #   run_test! do
        #     expect(status).to eq(200) 
        #   end
        # end
      end
    end
  end

  path "/my_collections/{id}" do
    include_context 'collections_with_objects'

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
        include_context 'rswag_include_spec_output'

        let(:id) { "collection_that_does_not_exist" }

        it 'returns a 404 when the user is not signed in' do
          expect(status).to eq(404) 
        end
      end

      response "200", "Object found" do
        include_context 'rswag_include_spec_output'
        let(:id) { @collections.first.id }
        run_test! do
          expect(status).to eq(200) 
        end
      end
    end
  end
end


#   with_options scope: :results do
#     parameter :mode, 'Show Objects or Collections', type: :string, default: 'objects'
#     parameter :show_subs, 'Show subcollections', type: :boolean, default: false
#     parameter :search_field, 'Field to search against', type: :string, default: 'all_fields'
#     parameter :q, 'Search Query', type: :string
#     parameter :sort, 'Sort results', type: :string, default: 'system_create_dtsi+desc'
    
#     # refine your search section (facet filters)
#     parameter :f, 'Facet filter', type: :array
#     # parameter :status_sim, 'Record Status', type: :array
#     # parameter :master_file_access_sim, 'Master File Access', type: :array
#     # parameter :person_sim, 'Names', :type :array
#     # parameter :file_count_isi, 'Number of files', type: :array
#     # mediatype
#     # Type (from Metadata)
#     # Depositor
#     # Collection
#   end


#   with_options scope: :collection, with_example: true do
#     parameter :id, 'The collection id. Accessed via my_collections/:id or my_collections?id=:id', type: :string
#     parameter :per_page, 'Number of results per page', type: :number, default: 9
#   end

#   get "/my_collections" do
#     it_behaves_like 'an api with authentication'

#     example "Listing the current users collections" do
#       # explanation "List all collections for the current user."
#       do_request
#       expect(status).to eq(200)
#     end

#     context "Mode" do
#       # let!(:ncols) { 3 }
#       # let!(:nobjs) { 2 }
#       # include_context 'collections_with_objects', 
#       #   num_collections=ncols, num_objects=nobjs

#       include_context 'collections_with_objects', 
#         num_collections=2, num_objects=3

      
#       example "Listing the current users objects" do
#         do_request(mode: 'objects')
#         json_response = JSON.parse(response_body)

#         # is_collection = json_response["response"]["facets"].select do |f|
#         #   f["name"] == "is_collection_sim"
#         # end.first["items"].first

#         # expect(is_collection["value"]).to eq "false"
#         # expect(is_collection["hits"]).to eq (@num_collections * @num_objects)


#         json_response["response"]["facets"].each do |facet|
#           if facet["name"] == "is_collection_sim"
#             facet_results = facet["items"].first
#             expect(facet_results["value"]).to eq "false"
#             expect(facet_results["hits"]).to eq 6
#           end
#         end
#       end
#     end

#     context "Page limit" do      
#       context "Single item per collection" do
#         include_context 'collections_with_objects', num_collections=3 

#         # TODO: dynamically add param to example title
#         example "Listing the current users collections with a page limit" do
#           request = {
#             per_page: 1
#           }
#           do_request(request)
#           json_response = JSON.parse(response_body)
#           pages = json_response['response']['pages']
          
#           expect(status).to eq(200)
#           expect(pages['first_page?']).to eq true
#           expect(pages['last_page?']).to eq false
#           expect(pages['limit_value']).to eq 1
#           expect(pages['total_pages']).to eq @collections.count
#         end
#       end

#       context "Multiple objects per collection" do
#         @num_objects=4
#         include_context 'collections_with_objects', num_collections=2, num_objects=@num_objects

#         example "Listing the current users collections with a page limit limits results per item, not per collection" do
#           request = {
#             per_page: 1
#           }
#           do_request(request)
#           json_response = JSON.parse(response_body)
#           pages = json_response['response']['pages']
          
#           expect(status).to eq(200)
#           expect(pages['first_page?']).to eq true
#           expect(pages['last_page?']).to eq false
#           expect(pages['limit_value']).to eq 1
#           expect(pages['total_pages']).to eq @collections.count * num_objects
#         end
#       end
#     end
#   end

#   get "/my_collections/:id" do
#     context '400' do
#       it_behaves_like 'a request for a collection that does not exist'
#     end

#     context "200" do
#       include_context 'collections_with_objects', num_objects=3

#       example "Listing a specific collection" do
#         request = {
#           id: @collections.first.id
#         }
#         do_request(request)
#         expect(status).to eq 200  
#       end
#     end

#   end
# end
