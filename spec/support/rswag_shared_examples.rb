# rswag / api shared examples

## 
# handle case where add_param is first param, use ? instead of &
#
# @param  [String] url
# @param  [Array]  param
# @return [String] uri
def add_param(url, param)
  uri = URI.parse(url)
  query_arr = URI.decode_www_form(uri.query || '') << param
  uri.query = URI.encode_www_form(query_arr)
  uri.to_s
end

shared_examples 'it has json licence information' do
  run_test! do
    licence_info = JSON.parse(response.body)['Licence']
    expect(licence_info.keys).to eq(%w[name url description])
  end
end

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

shared_examples 'a pretty json response', shared_context: :metadata do
  before do |example|
    submit_request(example.metadata)
    @normal_response = response.body.clone
    pretty_path = add_param(request.original_fullpath, ['pretty', 'true'])
    req_format = 'application/json'
    verb_func = method(example.metadata[:operation][:verb])
    verb_func.call(pretty_path, {}, CONTENT_TYPE: req_format, ACCEPT: req_format)
    @pretty_response = response.body.clone
  end
  # run_test! is a rswag specific function that 
  # submits the request and checks the response code matches the test definition
  run_test! do
    # same json but different formatting with ?pretty=true
    normal_json = JSON.parse(@normal_response)
    expect(JSON.pretty_generate(normal_json)).to eq @pretty_response
  end
end
