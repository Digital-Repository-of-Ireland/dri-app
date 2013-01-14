Given /^a Digital Object$/ do
  @digital_object = DRI::Model::Audio.new
end

When /^I commit the Digital Object$/ do
  @digital_object.save
end

Then /^I should be given a PID from the digital repository$/ do
 pending #@pid = @digital_object.persistent_identifier
end

When /^I add invalid metadata$/ do
  @tmp_xml = Nokogiri::XML(File.new(File.join('spec','fixtures','metadata_no_title_language.xml')).read)

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
