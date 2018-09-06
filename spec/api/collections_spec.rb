require 'api_spec_helper'

resource "collections" do

  header "Accept", "application/json"
  header "Host", "localhost"
  explanation "This route is used to view collections"

  get "/collections" do
    it_behaves_like 'an api with authentication'
  end
end
