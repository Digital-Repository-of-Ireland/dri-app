@web @req-17.6 @done @javascript
Feature:
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object with web forms

Background:
  Given I am logged in as "user1" in the group "cm" and accept cookies
  And a collection with pid "xxxx" and title "Test Collection" created by "user1"

Scenario: Constructing a valid Digital Object
  When I go to the "metadata" "upload" page for "xxxx"
  And I attach the metadata file "valid_metadata.xml"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion

Scenario Outline: Constructing a Digital Object with metadata that incorrect or incomplete
  When I go to the "collection" "show" page for "xxxx"
  And I follow the link to upload XML
  And I attach the metadata file "<metadata_file>"
  And I press the button to "ingest metadata"
  Then I should see a failure message for <case>

  Examples:
    | metadata_file                 | case             |
    | metadata_no_rights.xml        | invalid object   |
    | invalid_schema_metadata.xml   | invalid schema   |
    | invalid_xml_metadata.xml      | invalid metadata |

Scenario Outline: Constructing a valid Digital Object
  When I go to the "collection" "show" page for "xxxx"
  And I follow the link to upload XML
  And I attach the metadata file "<metadata_file>"
  And I press the button to "ingest metadata"
  Then I should see a success message for ingestion
  And the object should be of type <type>

  Examples:
    | metadata_file                 | type        |
    | dublin_core_pdfdoc_sample.xml | Text        |
    | SAMPLEA.xml                   | Sound       |

@test
Scenario: Adding a pdf asset to an object
  Given "user1" has created a Digital Object
  When I attach the asset file "sample_pdf.pdf"
  And I press the button to "upload a file"
  Then I should see a success message for file upload

Scenario: Replacing the metadata file of a Digital Object
  Given "user1" has created a Digital Object
  When I attach the metadata file "valid_metadata.xml"
  And I press the button to "upload metadata"
  Then I should see a success message for updating metadata

Scenario: Constructing a Digital Object using the web form
  When I go to the "collection" "show" page for "xxxx"
  And I follow the link to add an object
  When I enter valid metadata
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should see the valid metadata

Scenario: Constructing an invalid Digital Object using the web form
  When I go to the "collection" "show" page for "xxxx"
  And I follow the link to add an object
  When I enter invalid metadata
  And I press the button to "continue"
  Then I should not see a success message for ingestion

@review
Scenario: Constructing a Digital Object using the web form without setting a collection
  Given I am on the new Digital Object page
  And I press the button to "continue"
  And I select "input" from the selectbox for ingest methods
  And I press the button to "continue"
  When I enter valid metadata
  And I press the button to "continue"
  Then I should see a success message for ingestion
  And I should see the valid metadata

Scenario: Editing the metadata of a Digital Object using the web form
  Given "user1" has created a Digital Object
  When I go to the "object" "edit" page for "created" 
  And I enter modified metadata
  And I press the button to "save changes"
  Then I should see the modified metadata
  And I should see a success message for updating metadata

Scenario: Editing the metadata of a Digital Object with invalid metadata
  Given "user1" has created a Digital Object
  When I go to the "object" "edit" page for "created"  
  And I enter invalid metadata
  And I press the button to "save changes"
  Then I should not see a success message for updating metadata

Scenario: Adding multiple audio files for a Digital Object
  Given "user1" has created a Digital Object
  When I attach the asset file "sample_audio.mp3"
  And I press the button to "upload a file"
  Then I should see a success message for file upload
  When I follow the link to edit an object
  And I attach the asset file "sample_audio.mp3"
  And I press the button to "upload a file"
  Then I should see a success message for file upload

Scenario Outline: Adding an audio file that is not valid
  Given "user1" has created a Digital Object
  When I attach the asset file "<asset_name>"
  And I press the button to "upload a file"
  Then I should see a failure message for <case>

  Examples:
    | asset_name               | case              |
    | sample_audio.txt         | invalid file type |
#    | sample_invalid_audio.mp3 | invalid file type |

Scenario: Adding a file that contains a virus
  Given "user1" has created a Digital Object
  When I upload the virus file "sample_virus.mp3"
  Then I should see a failure message for virus detected

Scenario Outline: Editing an audio file where the file is invalid
  Given "user1" has created a Digital Object
  And I have added an audio file
  When I follow the link to edit an object
  And I attach the asset file "<asset_name>"
  And I press the button to "upload a file"
  Then I should see a failure message for <case>

  Examples:
    | asset_name               | case              |
    | sample_audio.txt         | invalid file type |
#    | sample_invalid_audio.mp3 | invalid file type |
