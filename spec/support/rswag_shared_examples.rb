# rswag / api shared examples
shared_examples 'a json api error' do
  run_test! do 
    json_response = JSON.parse(response.body)
    expect(json_response.keys).to include('errors')
  end
end

# @param [String | Regexp] message 
shared_examples 'a json api 401 error' do |message: nil|
  run_test! do
    error_detail = JSON.parse(response.body)["errors"][0]["detail"]
    message ||= 'You do not have sufficient access privileges to read this document'
    expect(error_detail).to match(message)
  end
end

# @param [String | Regexp] message 
shared_examples 'a json api 404 error' do |message: nil|
  run_test! do
    error_detail = JSON.parse(response.body)["errors"][0]["detail"]
    message ||= "The solr permissions search handler didn't return anything for id"
    expect(error_detail).to match(message)
    # it_behaves_like 'a json api error with', message: message
  end
end

# # nested shared example
# shared_examples 'a json api error with' do |message: nil|
#   error_detail = JSON.parse(response.body)["errors"][0]["detail"]
#   expect(error_detail).to match(message)
# end

