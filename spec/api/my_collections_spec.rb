# https://blog.codeship.com/producing-documentation-for-your-rails-api/
require 'api_spec_helper'

resource "my_collections" do

  header "Accept", "application/json"
  header "Host", "localhost"
  explanation "This route is used to view collections and objects for the current user"

  include_context 'collection_manager_user'
  include_context 'tmp_assets'

  before(:all) do
    @existential_error_regex = /"error":"Blacklight::Exceptions::InvalidSolrID: The solr permissions search handler didn't return anything for id/
  end

  # stay logged in by default, only one test requires you to be logged out
  before(:each) do
    sign_in @login_user
  end


  with_options scope: :results do
    parameter :mode, 'Show Objects or Collections', type: :string, default: 'Collections'
    parameter :show_subs, 'Show subcollections', type: :boolean, default: false
    parameter :per_page, 'Number of results per page', type: :number, default: 9
    parameter :search_field, 'Field to search against', type: :string, default: 'all_fields'
    parameter :q, 'Search Query', type: :string
    parameter :sort, 'Sort results', type: :string, default: 'system_create_dtsi+desc'
    
    # refine your search section (facet filters)
    parameter :f, 'Facet filter', type: :array
    # parameter :status_sim, 'Record Status', type: :array
    # parameter :master_file_access_sim, 'Master File Access', type: :array
    # parameter :person_sim, 'Names', :type :array
    # parameter :file_count_isi, 'Number of files', type: :array
    # mediatype
    # Type (from Metadata)
    # Depositor
    # Collection
  end


  get "/my_collections" do
    it_behaves_like 'an api with authentication'

    example "Listing the current users collections" do
      # explanation "List all collections for the current user."
      do_request
      expect(status).to eq(200)
    end

    context "Page limit" do
      with_options scope: :results, with_example: true do
        parameter :per_page, 'Number of results per page', type: :number, default: 9
      end
      
      context "Single item per collection" do
        include_context 'collections_with_items', num_collections=3 

        # TODO: dynamically add param to example title
        example "Listing the current users collections with a page limit" do
          request = {
            per_page: 1
          }
          do_request(request)
          json_response = JSON.parse(response_body)
          pages = json_response['response']['pages']
          
          expect(status).to eq(200)
          expect(pages['first_page?']).to eq true
          expect(pages['last_page?']).to eq false
          expect(pages['limit_value']).to eq 1
          expect(pages['total_pages']).to eq @collections.count
        end
      end

      context "Multiple items per collection" do
        @num_items=4
        include_context 'collections_with_items', num_collections=2, num_items=@num_items

        example "per_page limits per item, not per collection" do
          request = {
            per_page: 1
          }
          do_request(request)
          json_response = JSON.parse(response_body)
          pages = json_response['response']['pages']
          
          expect(status).to eq(200)
          expect(pages['first_page?']).to eq true
          expect(pages['last_page?']).to eq false
          expect(pages['limit_value']).to eq 1
          expect(pages['total_pages']).to eq @collections.count * num_items
        end
      end
    end
  end

  get "/my_collections/:id" do
    with_options scope: :collection, with_example: true do
      parameter :id, 'The collection id', type: :string
    end

    context '400' do
      it_behaves_like 'a request for a collection that does not exist'
    end

    context "200" do
      include_context 'collections_with_items', num_items=3

      example "Listing a specific collection" do
        request = {
          id: @collections.first.id
        }
        do_request(request)
        expect(status).to eq 200  
      end
    end

  end
end
