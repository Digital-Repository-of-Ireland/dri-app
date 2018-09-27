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
    json_response = JSON.parse(response.body)
    error_detail = json_response["errors"][0]["detail"]
    message ||= "You need to sign in or sign up before continuing."
    expect(error_detail).to match(message)
    expect(status).to eq(401) # 401 unauthorized
  end
end
