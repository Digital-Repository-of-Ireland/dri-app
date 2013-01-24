@construct @web
Feature: 
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object with web forms

Background:
  Given I am logged in as "user1"

Scenario: Navigating to the ingest page
  When I go to the home page
  Then I should see a link to ingest an object
  When I follow the link to ingest an object
  Then I should be on the new Digital Object page

Scenario: Constructing a valid Digital Object
  Given I am on the new Digital Object page
  When I attach the metadata file "valid_metadata.xml"
  And I press the button to ingest metadata
  Then I should see a success message for ingestion 

Scenario: Constructing a Digital Object with invalid XML metadata
  Given I am on the new Digital Object page
  When I attach the metadata file "invalid_xml_metadata.xml"
  And I press the button to ingest metadata
  Then I should see an error message for invalid metadata

Scenario: Constructing a Digital Object with metadata that does not conform to the schema
  Given I am on the new Digital Object page
  When I attach the metadata file "invalid_schema_metadata.xml"
  And I press the button to ingest metadata 
  Then I should see an error message for invalid schema

Scenario: Constructing a Digital Object with metadata that does not contain a required field
  Given I am on the new Digital Object page
  When I attach the metadata file "metadata_no_rights.xml"
  And I press the button to ingest metadata
  Then I should see an error message for invalid object

Scenario: Replacing the metadata file of a Digital Object
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  And I attach the metadata file "valid_metadata.xml"
  And I press the button to upload metadata
  Then I should see a success message for updating metadata

Scenario: Constructing a Digital Object using the web form
  Given I am on the new Digital Object page
  When I fill in "dri_model_audio_title" with "A Test Object"
  And I fill in "dri_model_audio_description" with "Created using the web form"
  And I fill in "dri_model_audio_broadcast_date" with "2013-01-16"
  And I fill in "dri_model_audio_rights" with "This is a statement of rights"
  #When I fill in the metadata form with valid data
  And I press the button to create record
  Then I should see a success message for ingestion
  And I should see "Title: A Test Object"
  And I should see "Description: Created using the web form"
  And I should see "Broadcast Date: 2013-01-16"

Scenario: Editing the metadata of a Digital Object using the web form
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Edit Audio"
  When I fill in "dri_model_audio_description" with "This is a test"
  And I fill in "dri_model_audio_broadcast_date" with "2013-01-01"
  And I press "Save Changes"
  When I follow "View record"
  Then I should see "Description: This is a test"
  And I should see "Broadcast Date: 2013-01-01"

Scenario: Adding and replacing the audio file for a Digital Object
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Upload Audio File:"
  When I attach the audio file "sample_audio.mp3"
  And I press "Upload Master File"
  Then I should see "File has been successfully uploaded"
  When I follow the link to edit an object
  Then I should see "A master audio file has already been uploaded"
  When I attach the audio file "sample_audio.mp3"
  And I press "Replace Master File"
  Then I should see "File has been successfully uploaded"

Scenario: Adding an audio file where the file extension is wrong
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Upload Audio File:"
  When I attach the audio file "sample_audio.txt"
  And I press "Upload Master File"
  Then I should see "The file does not appear to be a valid type"

Scenario: Editing an audio file where the file extension is wrong
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Upload Audio File:"
  When I attach the audio file "sample_audio.mp3"
  And I press "Upload Master File"
  Then I should see "File has been successfully uploaded"
  When I follow the link to edit an object
  Then I should see "A master audio file has already been uploaded"
  When I attach the audio file "sample_audio.txt"
  And I press "Replace Master File"
  Then I should see "The file does not appear to be a valid type"

Scenario: Adding an audio file that is not really an audio
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Upload Audio File:"
  When I attach the audio file "sample_invalid_audio.mp3"
  And I press "Upload Master File"
  Then I should see "The file does not appear to be a valid type"

Scenario: Editing an audio file that is not really an audio
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  Then I should see "Upload Audio File:"
  When I attach the audio file "sample_audio.mp3"
  And I press "Upload Master File"
  Then I should see "File has been successfully uploaded"
  When I follow the link to edit an object 
  Then I should see "A master audio file has already been uploaded"
  When I attach the audio file "sample_invalid_audio.mp3"
  And I press "Replace Master File"
  Then I should see "The file does not appear to be a valid type"
