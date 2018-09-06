# https://blog.codeship.com/producing-documentation-for-your-rails-api/
require 'api_spec_helper'

resource "my_collections" do
  before(:all) do
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
    @login_user = FactoryBot.create(:collection_manager)
    @auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
    @existential_error_regex = /"error":"Blacklight::Exceptions::InvalidSolrID: The solr permissions search handler didn't return anything for id/
  end

  before(:each) do
    sign_in @login_user
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end

  explanation "This route is used to view collections for the current user"

  # Headers which should be included in the request
  header "Accept", "application/json"
  header "Host", "localhost"
  # header "X-Api-Key", :auth_token

  get "/my_collections" do
    with_options with_example: true do
      parameter :mode, 'Show Objects or Collections', type: :string, default: 'Collections'
      parameter :show_subs, 'Show subcollections', type: :boolean, default: false
      parameter :per_page, 'Number of results per page', type: :number, default: 9
      parameter :search_field, '', type: :string, default: 'all_fields'
      parameter :q, 'Search Query'
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

    example "Listing the current users collections" do
      # explanation "List all collections for the current user."
      do_request
      expect(status).to eq(200)
    end
    example "Unauthorized access to the api" do
      explanation "Users must be authenticated before accessing the api"
      sign_out(@login_user)
      do_request
      expect(response_body).to eq @auth_error_response
      expect(status).to eq(401) # 401 unauthorized
    end
  end

  get "/my_collections/:id" do
    with_options with_example: true do
      parameter :id, 'The collection id', type: :string
    end

    context "404" do
      example "Listing a collection that does not exist" do
        request = {
          id: 'id_that_does_not_exist'
        }  
        do_request(request)
        expect(status).to eq 404
        expect(response_body).to match(@existential_error_regex)
      end
    end

    context "200" do
      before(:each) do
        @tmp_assets_dir = Dir.mktmpdir
        Settings.dri.files = @tmp_assets_dir

        @collection = FactoryBot.create(:collection)
        @collection[:creator] = [@login_user.email]
        @collection[:depositor] = @login_user.email
        @collection[:status] = "draft"
        @collection.apply_depositor_metadata(@login_user.to_s)

        3.times do |i|
          object = FactoryBot.create(:sound)
          object[:status] = "draft"
          object[:title] = ["Not a Duplicate#{i}"]
          object.apply_depositor_metadata(@login_user.to_s)
          object.save
          @collection.governed_items << object
        end

        @collection.save
      end

      after(:each) do
        @collection.delete
        FileUtils.remove_dir(@tmp_assets_dir, force: true)
      end

      example "Listing a specific collection" do
        request = {
          id: @collection.id
        }
        do_request(request)
        expect(status).to eq 200  
      end
    end

  end
end
