#Given /^a Digital Object$/ do
#  @digital_object = DRI::Batch.with_standard(:qdc, {id: ActiveFedora::Noid::Service.new.mint })
#end

When /^I commit the Digital Object$/ do
  @digital_object.save
end

Then /^I should be given a PID from the digital repository$/ do
  @digital_object.noid.should =~ /^\w\w\d\d\w\w\d\d\w$/
end

When /^I add (.*?) metadata$/ do |type|
  if type == "valid"
    filename = "valid_metadata.xml"
  else
    filename = "metadata_no_rights.xml"
  end

  @tmp_xml = Nokogiri::XML(File.new(File.join(cc_fixture_path, filename)).read)

  @digital_object.descMetadata.ng_xml = @tmp_xml
end

Then /^I should get an invalid Digital Object$/ do
  @digital_object.should_not be_valid
end
