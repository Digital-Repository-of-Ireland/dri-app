Given /^a Digital Object$/ do
  @digital_object = DRI::Model::Audio.new(:pid => NuigRnag::IdService.mint)
end

When /^I commit the Digital Object$/ do
  @digital_object.save
end

Then /^I should be given a PID from the digital repository$/ do
  @digital_object.id.should =~ /^#{NuigRnag::Application.config.id_namespace}:\w\w\d\d\w\w\d\d\w$/
end

When /^I add invalid metadata$/ do
  @tmp_xml = Nokogiri::XML(File.new(File.join('spec','fixtures','metadata_no_rights.xml')).read)

  if @digital_object.datastreams.has_key?("descMetadata")
    @digital_object.datastreams["descMetadata"].ng_xml = @tmp_xml
  else
    ds = DRI::Metadata::DublinCoreAudio.from_xml(@tmp_xml)
    @object.add_datastream ds, :dsid => 'descMetadata'
  end

end

When /^I add an invalid asset$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should get an invalid Digital Object$/ do
  @digital_object.should_not be_valid
end
