shared_context 'rswag_include_json_spec_output' do |example_name='application/json'|
  after do |example|
    example.metadata[:response][:examples] = { 
      example_name => JSON.parse(
        response.body, 
        symbolize_names: true
      ) 
    }
  end
end

shared_context 'rswag_include_xml_spec_output' do |example_name='application/xml'|
  after do |example|
    example.metadata[:response][:examples] = { 
      example_name => Nokogiri::XML(response.body) 
    }
  end
end
