# can only be used in the api context
# i.e. where 'rspec_api_documentation/dsl' or 'api_spec_helper' is loaded
shared_examples 'an api with authentication' do
  example "You need to sign in to acess this route" do
    # TODO support api keys so users can access api programmatically
    explanation "Users must be authenticated before accessing this route"
    sign_out_all
    do_request
    auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
    expect(response_body).to eq auth_error_response
    expect(status).to eq(401) # 401 unauthorized
  end
end

shared_examples 'an api without authentication' do |status_code=200|
  example "You do not need to sign in to acess this route" do
    explanation "Users do not need to be authenticated before accessing this route"
    sign_out_all
    do_request  
    auth_error_response = '{"error":"You need to sign in or sign up before continuing."}'
    expect(response_body).not_to eq auth_error_response
    expect(status).to eq(status_code)
  end
end

# assumes you are singed in if you need to be signed in to access the route
shared_examples 'a request for a collection that does not exist' do
  example "Listing a collection that does not exist" do
    existential_error_regex = %r{
      "error":"Blacklight::Exceptions::InvalidSolrID:
      \sThe\ssolr\spermissions\ssearch\shandler\s
      didn't\sreturn\sanything\sfor\sid
    }x
    request = {
      id: 'id_that_does_not_exist'
    }  
    do_request(request)
    expect(status).to eq(404)
    expect(response_body).to match(existential_error_regex)
  end
end
