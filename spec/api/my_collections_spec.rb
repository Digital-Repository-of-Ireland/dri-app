require 'swagger_helper'

describe "My Collections API" do
  path "/my_collections" do
    get "retrieves objects or collections for the current user" do
      produces 'application/json'

      include_context 'collection_manager_user'
      include_context 'tmp_assets'

      # stay logged in by default, only one test requires you to be logged out
      before(:each) do
        sign_in @login_user
      end

      response "401", "Must be signed in to access this route" do
        run_test! do 
          sign_out_all
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response_body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
        end
      end
    end
  end

  path "/my_collections/{id}" do
    include_context 'collections_with_objects', 
        num_collections=2, num_objects=3
    get "retrieves a specific collection" do
      produces 'application/json'#, 'application/ttl'
      parameter name: :id, :in => :path, :type => :string

      response "401", "Must be signed in to access this route" do

        # schema type: :object,
        #   properties: {
        #     id: { type: :string },
        #     title: { type: :string },
        #     organisation: { type: :string },
        #     license: { type: :string }
        #   }

        before do |example|
          sign_out_all
          submit_request(example.metadata)
        end

        after do |example|
          example.metadata[:response][:examples] = { 
            'application/json' => JSON.parse(
              response.body, 
              symbolize_names: true
            ) 
          }
        end

        let(:id) {@collections.first.id}

        it 'returns a 401 when the user is not signed in' do
          auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
          expect(response.body).to eq auth_error_response
          expect(status).to eq(401) # 401 unauthorized
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
