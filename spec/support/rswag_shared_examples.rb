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

shared_examples 'a pretty json response' do
  # parameter name: :pretty, in: :query, type: :boolean, required: true

  before do |example|
    submit_request(example.metadata)
    @normal_response = response.body.clone
    # pretty_config = {
    #   name: :pretty, 
    #   in: :query, 
    #   type: :boolean, 
    #   required: true, # not really a required param, 
    #   # but needs to be for rswag to include the param in the request
    #   default: true
    # }
    # pretty_metadata = example.metadata.clone
    # pretty_metadata[:operation][:parameters] << pretty_config
    byebug
    pretty_path = "#{request.fullpath}&pretty=true"
    get pretty_path, {}, { 
      CONTENT_TYPE: 'application/json', 
      ACCEPT: 'application/json' 
    }
    @pretty_response = response.body.clone
  end
  run_test! do
    # same json but different formatting with ?pretty=true
    expect(@normal_response).to_not eq @pretty_response
    expect(JSON.parse(@normal_response)).to eq JSON.parse(@pretty_response)
  end

  # parameter name: :pretty, in: :query, type: :boolean, required: false, 
  # context 'normal_response' do
  #   let(:pretty) { false }
  #   run_test! do
  #     @normal_response = response.body.clone
  #   end
  # end
  # context 'pretty_response' do
  #   let(:pretty) { true }
  # end
end

# # nested shared example
# shared_examples 'a json api error with' do |message: nil|
#   error_detail = JSON.parse(response.body)["errors"][0]["detail"]
#   expect(error_detail).to match(message)
# end

