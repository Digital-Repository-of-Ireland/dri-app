@ingest @req-17
Feature: 
  In order to add a digital object into the repository
  As an authenticated and authorised depositor
  I want to construct a Digital Object with web forms

Scenario: Constructing a valid Digital Object
  Given a metadata file "valid_metadata.xml"
  When I visit the new Digital Object page
  And I upload the metadata file "valid_metadata.xml"
  Then I should see "Audio object has been successfully ingested"
  And the Digital Object metadata should match "valid_metadata.xml"
 
Scenario: Constructing an invalid Digital Object
  Given a metadata file "invalid_metadata.xml"
  When I visit the new Digital Object page
  And I upload the metadata file "invalid_metadata.xml"
  Then I should see "Audio object has invalid metadata"
