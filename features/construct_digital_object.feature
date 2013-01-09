@construct @ingest @req-17
Feature: 
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object with web forms

Background:
  Given I am logged in as "user1"

Scenario: Constructing a valid Digital Object
  Given I am on the new Digital Object page
  When I attach the metadata file "valid_metadata.xml"
  And I press "Ingest Metadata" 
  Then I should see "Audio object has been successfully ingested"
 
Scenario: Constructing an invalid Digital Object
  Given I am on the new Digital Object page
  When I attach the metadata file "invalid_metadata.xml"
  And I press "Ingest Metadata"
  Then I should see "Audio object has invalid metadata"
