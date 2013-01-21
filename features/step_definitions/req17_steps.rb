Given /^the asset SAMPLEA$/ do
  @SAMPLEA = File.join(cc_fixture_path,'SAMPLEA')

  assert Pathname.new(@SAMPLEA).exist?
end

Given /^that the asset is only (\d+) file$/ do |count|
  if @SAMPLEA.kind_of?(Array)
    @SAMPLEA.length.to_s.should eq(count)  
  else
    File.directory?(@SAMPLEA).should_not be_true
  end
end

Given /^a metadata file SAMPLEA\.xml$/ do
  @SAMPLEAXML = File.join(cc_fixture_path,'SAMPLEA.xml')

  assert Pathname.new(@SAMPLEAXML).exist?
end

When /^I ingest the files SAMPLEA and SAMPLEA\.xml$/ do
  steps %{
    Given I am on the new Digital Object page
    When I attach the metadata file "SAMPLEA.xml"
    And I press "Ingest Metadata"
    Then I should see "Audio object has been successfully ingested"

    When I follow "Edit this record"
    Then I should see "Upload Audio File:"
    When I attach the audio file "SAMPLEA.mp3"
    And I press "Upload Master File"
    Then I should see "File has been successfully uploaded"
  }
end

Then /^I validate the metadata file$/ do
  steps %{
    Given I am on the new Digital Object page
    When I attach the metadata file "SAMPLEA.xml"
    And I press "Ingest Metadata"
    Then I should see "Audio object has been successfully ingested"

    Given I am on the new Digital Object page
    When I attach the metadata file "invalid_schema_metadata.xml"
    And I press "Ingest Metadata"
    Then I should see "Validation Errors:"
  }
end

Then /^I attempt to validate the data file against a mime type database$/ do
  steps %{
    Given I have created a Digital Object
    Then I should see a link to "Edit this record"
    When I follow "Edit this record"
    Then I should see "Upload Audio File:"
    When I attach the audio file "sample_invalid_audio.mp3"
    And I press "Upload Master File"
    Then I should see "The file does not appear to be a valid type"
  }
end

Then /^I inspect the asset for the file metadata and record this information$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I ingest the assest with the metadata$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should have a PID for the object in the digital repository$/ do
  steps %{
    Given a Digital Object
    When I commit the Digital Object
    Then I should be given a PID from the digital repository
  }
end
