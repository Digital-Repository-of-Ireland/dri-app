require 'api_spec_helper'

resource "bookmarks" do

  header "Accept", "application/json"
  header "Host", "localhost"
  explanation "This route is used to view bookmarks"

  # TODO possibly remove this route?
  get "/bookmarks" do
    # don't have to be signed in to access /bookmarks
    # it_behaves_like 'an api with authentication'
    it_behaves_like 'an api without authentication', status_code=302
  end
end
