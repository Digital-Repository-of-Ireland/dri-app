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

shared_examples 'it has json licence information' do |key='Licence'|
  run_test! do
    licence_info = JSON.parse(response.body)[key]
    expect(licence_info.keys).to eq(%w[name url description])
  end
end

shared_examples 'it has no json licence information' do |key='Licence'|
  run_test! do
    licence_info = JSON.parse(response.body)[key]
    expect(licence_info).to be nil
  end
end

shared_examples 'it has json doi information' do |key='Doi'|
  run_test! do
    doi_details = JSON.parse(response.body)[key][0]
    expect(doi_details.keys.sort).to eq(%w[created_at url version]) 
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

shared_examples 'a pretty json response' do
  before do |example|
    # submit normal request
    submit_request(example.metadata)
    @normal_response = response.body.clone
    # add pretty param and resubmit request
    pretty_path = add_param(request.original_fullpath, ['pretty', 'true'])
    req_format = 'application/json'
    http_verb = example.metadata[:operation][:verb]
    verb_func = method(http_verb)
    # include body for post requests
    body = http_verb == :post ? request.body : {}
    verb_func.call(pretty_path, body, CONTENT_TYPE: req_format, ACCEPT: req_format)
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
