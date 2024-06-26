# rswag / api shared examples

shared_examples 'a json response with' do |licence_key: false, copyright_key: false, doi_key: false, related_objects_key: false|
  run_test! do
    json_response = JSON.parse(response.body)
    expect(json_response[licence_key].keys.sort).to eq(%w[name url description]) if licence_key
    expect(json_response[copyright_key].keys.sort).to eq(%w[name copyright url description]) if copyright_key
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

shared_examples 'it has json copyright information' do |key='Copyright'|
  run_test! do
    copyright_info = JSON.parse(response.body)[key]
    expect(copyright_info.keys).to eq(%w[name url description])
  end
end

shared_examples 'it has no json copyright information' do |key='Copyright'|
  run_test! do
    copyright_info = JSON.parse(response.body)[key]
    expect(copyright_info).to be nil
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

# @param [String] field
shared_examples 'a search response with no false positives' do |field|
  run_test! do
    json_body = JSON.parse(response.body)
    json_object = json_body['response']['docs'].first

    # no false positives
    expect(json_body['response']['docs'].count).to eq(1)
    expect(json_object["#{field}_tesim"]).to eq(bind_search_param)

    # # parsing the object_profile seems slightly faster than looking up the solr name
    # # may be useful in future if response changes and no longer returns duplicate info
    # key = Solrizer.solr_name(field)
    # expect(json_body['response']['docs'].first[key]).to eq([q])
  end
end

# @param [Controller] controller
shared_examples 'it accepts search_field params' do |controller, search_param|
  context 'search_field no output' do
    # for searches with each remaining search_field
    fields_hash = controller.blacklight_config.search_fields
    fields_to_test = fields_hash.keys.reject do |field|
      # exclude aggregate fields
       %w[all_fields person place].include?(field)
    end.sort

    fields_to_test.each do |field|
      context "#{field} search" do
        let(search_param)  { "fancy #{field}" }
        let(:search_field) { field }

        context_args = [field, fields_to_test]
        spec_args = [field]

        include_context 'catch search false positives', *context_args  do
          it_behaves_like 'a search response with no false positives', *spec_args
        end
      end
    end
  end
end
