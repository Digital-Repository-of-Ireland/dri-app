# https://blog.codeship.com/producing-documentation-for-your-rails-api/
require 'api_spec_helper'

resource "my_collections" do
  before(:all) do
    UserGroup::Group.find_or_create_by(name: SETTING_GROUP_CM, description: "collection manager test group")
    login_user = FactoryBot.create(:collection_manager)
    sign_in login_user
  end

  after(:all) do
    UserGroup::Group.find_by(name: SETTING_GROUP_CM).delete
  end

  # Headers which should be included in the request
  header "Accept", "application/vnd.api+json"
  # header "X-Api-Key", :auth_token

  # A specific endpoint
  get "/my_collections.json" do
    # # Which GET/POST params can be included in the request and what do they do?
    # parameter :sort, "Sort the response. Can be sorted by #{ResidencesIndex::SORTABLE_FIELDS.join(',')}. They are comma separated and include - in front to sort in descending order. Example: -rooms,cost"
    # parameter :number, "Which page number of results would you like.", scope: :page

    # let(:number) { 1 }
    # let(:sort) { "-rooms,cost" }

    # We can provide multiple examples for each endpoint, highlighting different aspects of them.
    example "Listing the current users collections" do
      # explanation "List all collections for the current user."

      # 2.times { create(:residence, rooms: (1..6).to_a.sample) }

      do_request

      expect(status).to eq(200)
    end
  end
end
