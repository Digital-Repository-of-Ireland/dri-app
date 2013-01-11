@construct @ingest @req-17
Feature: 
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object with web forms

Background:
  Given I am logged in as "user1"

Scenario: Navigating to the ingest page
  When I go to the home page
  Then I should see a link to "/audios/new" with text "Ingest" 
  When I follow "Ingest"
  Then I should be on the new Digital Object page

Scenario: Constructing a valid Digital Object
  Given I am on the new Digital Object page
  When I attach the metadata file "valid_metadata.xml"
  And I press "Ingest Metadata" 
  Then I should see "Audio object has been successfully ingested"
 
Scenario: Constructing an invalid Digital Object
  Given I am on the new Digital Object page
  When I attach the metadata file "invalid_metadata.xml"
  And I press "Ingest Metadata"
  Then I should see "Validation Errors:"

Scenario: Editing a Digital Object
  Given I have created a Digital Object
  Then I should see a link to "Edit this record"
  When I follow "Edit this record"
  Then I should see "Edit Audio"
  When I attach the metadata file "valid_metadata.xml"
  And I press "Upload Metadata"
  Then I should see "Metadata has been successfully updated"
