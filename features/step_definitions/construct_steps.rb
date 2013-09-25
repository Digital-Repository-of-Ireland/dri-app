Given /^a Digital Object$/ do
  @digital_object = Batch.new(:pid => Sufia::IdService.mint)
end

When /^I commit the Digital Object$/ do
  @digital_object.save
end

Then /^I should be given a PID from the digital repository$/ do
  @digital_object.id.should =~ /^#{NuigRnag::Application.config.id_namespace}:\w\w\d\d\w\w\d\d\w$/
end

When /^I add (.*?) metadata$/ do |type|
  if type == "valid"
    filename = "valid_metadata.xml"
  else
    filename = "metadata_no_rights.xml"
  end

  @tmp_xml = Nokogiri::XML(File.new(File.join(cc_fixture_path, filename)).read)

  if @digital_object.datastreams.has_key?("descMetadata")
    @digital_object.datastreams["descMetadata"].ng_xml = @tmp_xml
  else
    ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
    @digital_object.add_datastream ds, :dsid => 'descMetadata'
  end
end

Then /^I should get an invalid Digital Object$/ do
  @digital_object.should_not be_valid
end
