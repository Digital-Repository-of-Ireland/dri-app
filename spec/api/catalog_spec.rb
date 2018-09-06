require 'api_spec_helper'

resource "catalog" do

  header "Accept", "application/json"
  header "Host", "localhost"
  explanation "This route is used to view all objects in the repository"

  get "/catalog" do
    # don't have to be signed in to access /catalogue
    # it_behaves_like 'an api with authentication'
    it_behaves_like 'an api without authentication'
  end
end
