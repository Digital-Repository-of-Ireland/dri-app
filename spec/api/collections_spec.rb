require 'api_spec_helper'

resource "collections" do

  header "Accept", "application/json"
  header "Host", "localhost"
  explanation "This route is used to view the id, colelction_title and \
  governing_collection of collections for the current user"

  get "/collections" do
    it_behaves_like 'an api with authentication'
  end

  get "collections/:id" do
    with_options with_example: true do
      parameter :id, 'The collection id', type: :string
      parameter :per_page, 'Number of collections per page', type: :number
    end

    context '400' do
      it_behaves_like 'a request for a collection that does not exist'
    end
  end
end
