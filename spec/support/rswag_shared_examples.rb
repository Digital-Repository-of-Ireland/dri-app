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

shared_examples 'a json response with' do |licence_key: false, doi_key: false, related_objects_key: false|
  run_test! do
    json_response = JSON.parse(response.body)
    expect(json_response[licence_key].keys.sort).to eq(%w[name url description]) if licence_key
    expect(json_response[doi_key].keys.sort).to eq(%w[created_at url version]) if doi_key
    expect(json_response[related_objects_key].keys.sort).to eq(%w[doi relation url]) if related_objects_key
  end
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

shared_examples 'it has json related objects information' do |key='RelatedObjects'|
  run_test! do
    related_objects_details = JSON.parse(response.body)[key][0]
    expect(related_objects_details.keys.sort).to eq(%w[doi relation url])
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
  let(:pretty) {true}
  run_test! do
    expect(JSON.pretty_generate(JSON.parse(response.body))).to eq(response.body)
  end
end
