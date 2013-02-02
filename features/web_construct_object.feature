@web
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
#  When I select a collection
  And I press the button to continue
  And I select audio from the selectbox for object type
  And I press the button to continue
  And I select upload from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "valid_metadata.xml"
  And I press the button to ingest metadata
  Then I should see a success message for ingestion 

Scenario: Constructing a Digital Object with invalid XML metadata
  Given I am on the new Digital Object page
#  When I select a collection
  And I press the button to continue
  And I select audio from the selectbox for object type
  And I press the button to continue
  And I select upload from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "invalid_xml_metadata.xml"
  And I press the button to ingest metadata
  Then I should see an error message for invalid metadata

Scenario: Constructing a Digital Object with metadata that does not conform to the schema
  Given I am on the new Digital Object page
#  When I select a collection
  And I press the button to continue
  And I select audio from the selectbox for object type
  And I press the button to continue
  And I select upload from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "invalid_schema_metadata.xml"
  And I press the button to ingest metadata 
  Then I should see an error message for invalid schema

Scenario: Constructing a Digital Object with metadata that does not contain a required field
  Given I am on the new Digital Object page
#  When I select a collection
  And I press the button to continue
  And I select audio from the selectbox for object type
  And I press the button to continue
  And I select upload from the selectbox for ingest methods
  And I press the button to continue
  And I attach the metadata file "metadata_no_rights.xml"
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
#  When I select a collection
  And I press the button to continue
  And I select audio from the selectbox for object type
  And I press the button to continue
  And I select input from the selectbox for ingest methods
  And I press the button to continue
  When I enter valid metadata
  And I press the button to continue
  Then I should see a success message for ingestion
  And I should see the valid metadata

Scenario: Editing the metadata of a Digital Object using the web form
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  And I enter modified metadata
  And I press the button to save changes
  And I follow the link to view record
  Then I should see the modified metadata

Scenario: Adding and replacing the audio file for a Digital Object
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  And I attach the audio file "sample_audio.mp3"
  And I press the button to upload a file
  Then I should see a success message for file upload
  When I follow the link to edit an object
  And I attach the audio file "sample_audio.mp3"
  And I press the button to replace a file
  Then I should see a success message for file upload

Scenario: Adding an audio file where the file extension is wrong
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  When I attach the audio file "sample_audio.txt"
  And I press the button to upload a file
  Then I should see an error message for invalid file type

Scenario: Editing an audio file where the file extension is wrong
  Given I have created a Digital Object
  And I have added an audio file  
  When I follow the link to edit an object
  And I attach the audio file "sample_audio.txt"
  And I press the button to replace a file
  Then I should see an error message for invalid file type

Scenario: Adding an audio file that is not really an audio
  Given I have created a Digital Object
  Then I should see a link to edit an object
  When I follow the link to edit an object
  And I attach the audio file "sample_invalid_audio.mp3"
  And I press the button to upload a file
  Then I should see an error message for invalid file type

Scenario: Editing an audio file that is not really an audio
  Given I have created a Digital Object
  And I have added an audio file
  When I follow the link to edit an object 
  And I attach the audio file "sample_invalid_audio.mp3"
  And I press the button to replace a file
  Then I should see an error message for invalid file type
